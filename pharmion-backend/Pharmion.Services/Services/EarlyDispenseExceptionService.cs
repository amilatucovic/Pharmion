using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;
using Pharmion.Services.StateMachines.ReservationStateMachine;

namespace Pharmion.Services.Services
{
    public class EarlyDispenseExceptionService : IEarlyDispenseExceptionService
    {
        private readonly PharmionDbContext _context;

        public EarlyDispenseExceptionService(PharmionDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<EarlyDispenseExceptionResponse>> GetAsync(
            EarlyDispenseExceptionSearchObject search)
        {
            var query = _context.EarlyDispenseExceptions
                .Include(e => e.PrescriptionItem)
                    .ThenInclude(pi => pi.Product)
                .Include(e => e.PrescriptionItem)
                    .ThenInclude(pi => pi.Prescription)
                        .ThenInclude(p => p.Patient)
                .Include(e => e.Reservation)
                    .ThenInclude(r => r.Pharmacy)
                .Include(e => e.ApprovedByPharmacist)
                .AsQueryable();

            query = query.Where(e => e.Reservation.ReservationState != "DraftReservationState");


            if (search.PharmacyId.HasValue)
                query = query.Where(e => e.Reservation.PharmacyId == search.PharmacyId.Value);

            if (search.PatientId.HasValue)
                query = query.Where(e => e.PrescriptionItem.Prescription.PatientId == search.PatientId.Value);

            if (search.Status.HasValue)
                query = query.Where(e => e.Status == search.Status.Value);

            if (search.ReasonType.HasValue)
                query = query.Where(e => e.ReasonType == search.ReasonType.Value);

            if (!string.IsNullOrEmpty(search.PatientName))
                query = query.Where(e =>
                    (e.PrescriptionItem.Prescription.Patient.FirstName + " " +
                     e.PrescriptionItem.Prescription.Patient.LastName)
                    .Contains(search.PatientName));

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync();

            query = query.OrderByDescending(e => e.RequestedAt);

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
                query = query.Skip(search.Page.Value * search.PageSize.Value)
                             .Take(search.PageSize.Value);

            var items = await query.ToListAsync();

            return new PagedResult<EarlyDispenseExceptionResponse>
            {
                Items = items.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<EarlyDispenseExceptionResponse> GetByIdAsync(int id)
        {
            var e = await _context.EarlyDispenseExceptions
                .Include(e => e.PrescriptionItem)
                    .ThenInclude(pi => pi.Product)
                .Include(e => e.PrescriptionItem)
                    .ThenInclude(pi => pi.Prescription)
                        .ThenInclude(p => p.Patient)
                .Include(e => e.Reservation)
                    .ThenInclude(r => r.Pharmacy)
                .Include(e => e.ApprovedByPharmacist)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (e == null)
                throw new NotFoundException($"Early dispense exception with ID {id} not found.");

            return MapToResponse(e);
        }

        public async Task<EarlyDispenseExceptionResponse> ApproveAsync(
            int id, int pharmacistId, ApproveExceptionRequest request)
        {
            var exception = await _context.EarlyDispenseExceptions
        .Include(e => e.PrescriptionItem)
        .Include(e => e.Reservation)
        .FirstOrDefaultAsync(e => e.Id == id)
        ?? throw new UserException("Exception not found.");

            var pharmacist = await _context.Pharmacists.FindAsync(pharmacistId)
                ?? throw new UserException("Pharmacist not found.");

            if (!pharmacist.IsAdministrator &&
                pharmacist.PharmacyId != exception.Reservation!.PharmacyId)
                throw new ForbiddenException();

            if (exception.Status != ExceptionStatus.Pending)
                throw new UserException("Only pending exceptions can be approved.");

           

            exception.Status = ExceptionStatus.Approved;
            exception.ApprovedAt = DateTime.UtcNow;
            exception.ApprovedByPharmacistId = pharmacistId;
            exception.Note = request.Note;

            await _context.SaveChangesAsync();

            return (await GetByIdAsync(id))!;
        }

        public async Task<EarlyDispenseExceptionResponse> RejectAsync(int id, int pharmacistId, RejectExceptionRequest request)
        {

            var exception = await _context.EarlyDispenseExceptions
                .Include(e => e.PrescriptionItem)
                .Include(e => e.Reservation) 
                .FirstOrDefaultAsync(e => e.Id == id)
                ?? throw new UserException("Exception not found.");
            var pharmacist = await _context.Pharmacists.FindAsync(pharmacistId)
    ?? throw new UserException("Pharmacist not found.");

            if (!pharmacist.IsAdministrator &&
                pharmacist.PharmacyId != exception.Reservation!.PharmacyId)
                throw new ForbiddenException();

            if (exception.Status != ExceptionStatus.Pending)
                throw new UserException("Only pending exceptions can be rejected.");

            exception.Status = ExceptionStatus.Rejected;
            exception.ApprovedAt = DateTime.UtcNow;
            exception.ApprovedByPharmacistId = pharmacistId;
            exception.Note = request.Note;

            var reservation = exception.Reservation;
          
            if (reservation != null &&
                reservation.ReservationState == nameof(SubmittedReservationState))
            {
                var items = await _context.ReservationItems
                    .Where(i => i.ReservationId == reservation.Id)
                    .ToListAsync();

                foreach (var item in items)
                {
                    var inventoryItem = await _context.InventoryItems
                        .FirstOrDefaultAsync(i =>
                            i.PharmacyId == reservation.PharmacyId &&
                            i.ProductId == item.ProductId);
                    if (inventoryItem != null)
                    {
                        inventoryItem.ReservedQuantity -= item.Quantity;
                        if (inventoryItem.ReservedQuantity < 0)
                            inventoryItem.ReservedQuantity = 0;
                    }
                }

                reservation.ReservationState = nameof(RejectedReservationState);
                reservation.RejectionReason = $"Early dispense request rejected. Reason: {request.Note}";
                reservation.RejectedAt = DateTime.UtcNow;
                reservation.RejectedByPharmacistId = pharmacistId;

                _context.Notifications.Add(new Notification
                {
                    UserId = reservation.PatientId,
                    Title = "Reservation rejected",
                    Message = $"Your reservation RES-{reservation.Id} was rejected because the early dispense request was denied. Reason: {request.Note}",
                    Template = NotificationTemplate.ReservationRejected,
                    Type = NotificationType.InApp,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow,
                    ReservationId = reservation.Id
                });
            }

            await _context.SaveChangesAsync();
            return (await GetByIdAsync(id))!;
        }

        private EarlyDispenseExceptionResponse MapToResponse(EarlyDispenseException e)
        {
            var patient = e.PrescriptionItem?.Prescription?.Patient;
            var product = e.PrescriptionItem?.Product;
            var pharmacy = e.Reservation?.Pharmacy;
            var approvedBy = e.ApprovedByPharmacist;

            return new EarlyDispenseExceptionResponse
            {
                Id = e.Id,
                PrescriptionItemId = e.PrescriptionItemId,
                ProductName = product?.Name ?? string.Empty,
                Dosage = e.PrescriptionItem?.Dosage ?? string.Empty,
                PeriodDays = e.PrescriptionItem?.PeriodDays ?? 0,
                NextEligibleDispenseAt = e.PrescriptionItem?.NextEligibleDispenseAt,
                LastDispensedAt = e.PrescriptionItem?.LastDispensedAt,
                ReservationId = e.ReservationId,
                PatientName = patient != null
                    ? $"{patient.FirstName} {patient.LastName}"
                    : string.Empty,
                PatientEmail = patient?.Email ?? string.Empty,
                PharmacyName = pharmacy?.Name ?? string.Empty,
                PharmacyId = pharmacy?.Id ?? 0,
                RequestedAt = e.RequestedAt,
                Status = e.Status,
                ReasonType = e.ReasonType,
                OtherReason = e.OtherReason,
                Note = e.Note,
                ApprovedAt = e.ApprovedAt,
                ApprovedByPharmacistName = approvedBy != null
                    ? $"{approvedBy.FirstName} {approvedBy.LastName}"
                    : null
            };
        }
    }
}