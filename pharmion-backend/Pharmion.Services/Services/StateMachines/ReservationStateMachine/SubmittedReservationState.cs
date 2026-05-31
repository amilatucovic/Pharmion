using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;


namespace Pharmion.Services.StateMachines.ReservationStateMachine
{
    public class SubmittedReservationState : BaseReservationState
    {
        public SubmittedReservationState(
            IServiceProvider serviceProvider,
            PharmionDbContext context,
            IMapper mapper) : base(serviceProvider, context, mapper)
        {
        }

        public override async Task<ReservationResponse> ApproveAsync(int id, int pharmacistId)
        {
            var entity = await _context.Reservations
                .Include(r => r.Items)
                .FirstOrDefaultAsync(r => r.Id == id);
            if (entity == null)
                throw new UserException("Reservation not found");

            var pharmacist = await _context.Pharmacists.FindAsync(pharmacistId);
            if (pharmacist == null || (!pharmacist.IsAdministrator && pharmacist.PharmacyId != entity.PharmacyId))
                throw new UserException("You can only approve reservations from your pharmacy");
            if (!entity.Items.Any())
                throw new UserException("Cannot approve reservation with no items");

            var hasPendingException = await _context.EarlyDispenseExceptions
        .AnyAsync(e => e.ReservationId == id && e.Status == ExceptionStatus.Pending);
            if (hasPendingException)
                throw new UserException("Reservation cannot be approved while there are pending early dispense exceptions.");


            entity.ReservationState = nameof(ApprovedReservationState);
            entity.ApprovedAt = DateTime.UtcNow;
            entity.ApprovedByPharmacistId = pharmacistId;

            AddNotification(
                entity.PatientId,
                "Reservation approved",
                $"Your reservation RES-{entity.Id} is approved. Please select payment method.",
                NotificationTemplate.ReservationApproved,
                entity.Id);

            await _context.SaveChangesAsync();
            return _mapper.Map<ReservationResponse>(entity);
        }

        public override async Task<ReservationResponse> RejectAsync(int id, int pharmacistId, string reason)
        {
            var entity = await _context.Reservations.FindAsync(id);
            if (entity == null)
                throw new UserException("Reservation not found");

            var pharmacist = await _context.Pharmacists.FindAsync(pharmacistId);
            if (pharmacist == null || (!pharmacist.IsAdministrator && pharmacist.PharmacyId != entity.PharmacyId))
                throw new UserException("You can only reject reservations from your pharmacy");

            await ReturnReservedInventoryAsync(entity);

            entity.ReservationState = nameof(RejectedReservationState);
            entity.RejectionReason = reason;
            entity.RejectedAt = DateTime.UtcNow;
            entity.RejectedByPharmacistId = pharmacistId;

            AddNotification(
                entity.PatientId,
                "Reservation rejected",
                $"Your reservation RES-{entity.Id} is rejected. Reason: {reason}",
                NotificationTemplate.ReservationRejected,
                entity.Id);

            await _context.SaveChangesAsync();
            return _mapper.Map<ReservationResponse>(entity);
        }

        public override async Task<ReservationResponse> CancelAsync(int id, int userId, string reason)
        {
            var entity = await _context.Reservations.FindAsync(id);
            if (entity == null)                          
                throw new UserException("Reservation not found");
            await ReturnReservedInventoryAsync(entity);

            entity.ReservationState = nameof(CancelledReservationState);
            entity.CancellationReason = reason;
            entity.CancelledAt = DateTime.UtcNow;
            entity.CancelledByUserId = userId;

            var pharmacist = await _context.Pharmacists.FindAsync(userId);
            var patient = await _context.Patients.FindAsync(entity.PatientId);
            var patientName = patient != null ? $"{patient.FirstName} {patient.LastName}" : "Pacijent";
            if (pharmacist != null)
            {
                var pharmacistName = $"{pharmacist.FirstName} {pharmacist.LastName}";
                AddNotification(entity.PatientId,
                    "Reservation cancelled",
                    $"Pharmacist {pharmacistName} has cancelled your reservation RES-{entity.Id}. Reason: {reason}",
                    NotificationTemplate.ReservationCancelledByPharmacist, entity.Id);
            }
            else
            {
                var pharmacists = await _context.Pharmacists
                   .Where(p => p.PharmacyId == entity.PharmacyId)
                   .ToListAsync();
                foreach (var ph in pharmacists)
                {
                    AddNotification(ph.Id,
                        "Reservation cancelled",
                        $"{patientName} has cancelled reservation RES-{entity.Id}.",
                        NotificationTemplate.ReservationCancelled, entity.Id);
                }
            }

            await _context.SaveChangesAsync();
            return _mapper.Map<ReservationResponse>(entity);
        }
    }
 }