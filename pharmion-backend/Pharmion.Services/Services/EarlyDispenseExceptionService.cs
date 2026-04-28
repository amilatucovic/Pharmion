using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;

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

        public async Task<EarlyDispenseExceptionResponse?> GetByIdAsync(int id)
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

            return e == null ? null : MapToResponse(e);
        }

        public async Task<EarlyDispenseExceptionResponse> ApproveAsync(
            int id, int pharmacistId, ApproveExceptionRequest request)
        {
            var exception = await _context.EarlyDispenseExceptions
                .Include(e => e.PrescriptionItem)
                .FirstOrDefaultAsync(e => e.Id == id)
                ?? throw new UserException("Exception not found.");

            if (exception.Status != ExceptionStatus.Pending)
                throw new UserException("Only pending exceptions can be approved.");

            exception.Status = ExceptionStatus.Approved;
            exception.ApprovedAt = DateTime.UtcNow;
            exception.ApprovedByPharmacistId = pharmacistId;
            exception.Note = request.Note;

            await _context.SaveChangesAsync();

            return (await GetByIdAsync(id))!;
        }

        public async Task<EarlyDispenseExceptionResponse> RejectAsync(
          int id, int pharmacistId, RejectExceptionRequest request)
        {
            var exception = await _context.EarlyDispenseExceptions
                .Include(e => e.PrescriptionItem)
                .FirstOrDefaultAsync(e => e.Id == id)
                ?? throw new UserException("Exception not found.");

            if (exception.Status != ExceptionStatus.Pending)
                throw new UserException("Only pending exceptions can be rejected.");

            exception.Status = ExceptionStatus.Rejected;
            exception.ApprovedAt = DateTime.UtcNow;
            exception.ApprovedByPharmacistId = pharmacistId;
            exception.Note = request.Note;

            
            var reservationItem = await _context.ReservationItems
                .Include(ri => ri.Reservation)
                    .ThenInclude(r => r.Items)
                .FirstOrDefaultAsync(ri =>
                    ri.ReservationId == exception.ReservationId &&
                    ri.PrescriptionItemId == exception.PrescriptionItemId);

            if (reservationItem != null)
            {
                _context.ReservationItems.Remove(reservationItem);

               
                var reservation = reservationItem.Reservation!;
                reservation.Items.Remove(reservationItem);
                reservation.TotalAmount = reservation.Items.Sum(i => i.LineTotal);
                reservation.PatientPaysAmount = reservation.Items.Sum(i => i.PatientPart);
                reservation.InsurancePaysAmount = reservation.Items.Sum(i => i.InsurancePart);
                reservation.UpdatedAt = DateTime.UtcNow;

           
                var inventoryItem = await _context.InventoryItems
                    .FirstOrDefaultAsync(inv =>
                        inv.PharmacyId == reservation.PharmacyId &&
                        inv.ProductId == reservationItem.ProductId);

                if (inventoryItem != null)
                {
                    inventoryItem.ReservedQuantity -= reservationItem.Quantity;
                    if (inventoryItem.ReservedQuantity < 0)
                        inventoryItem.ReservedQuantity = 0;
                }
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