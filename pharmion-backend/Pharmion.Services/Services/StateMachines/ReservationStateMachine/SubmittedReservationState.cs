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
            if (pharmacist == null || pharmacist.PharmacyId != entity.PharmacyId)
                throw new UserException("You can only approve reservations from your pharmacy");
            if (!entity.Items.Any())
                throw new UserException("Cannot approve reservation with no items");

            entity.ReservationState = nameof(ApprovedReservationState);
            entity.ApprovedAt = DateTime.UtcNow;
            entity.ApprovedByPharmacistId = pharmacistId;

            AddNotification(
                entity.PatientId,
                "Rezervacija odobrena",
                $"Vaša rezervacija RES-{entity.Id} je odobrena. Odaberite metodu plaćanja.",
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
            if (pharmacist == null || pharmacist.PharmacyId != entity.PharmacyId)
                throw new UserException("You can only reject reservations from your pharmacy");

            await ReturnReservedInventoryAsync(entity);

            entity.ReservationState = nameof(RejectedReservationState);
            entity.RejectionReason = reason;
            entity.RejectedAt = DateTime.UtcNow;
            entity.RejectedByPharmacistId = pharmacistId;

            AddNotification(
                entity.PatientId,
                "Rezervacija odbijena",
                $"Vaša rezervacija RES-{entity.Id} je odbijena. Razlog: {reason}",
                NotificationTemplate.ReservationRejected,
                entity.Id);

            await _context.SaveChangesAsync();
            return _mapper.Map<ReservationResponse>(entity);
        }

        public override async Task<ReservationResponse> CancelAsync(int id, int userId, string reason)
        {
            var entity = await _context.Reservations.FindAsync(id);
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
                    "Rezervacija otkazana",
                    $"Farmaceut {pharmacistName} je otkazao Vašu rezervaciju RES-{entity.Id}. Razlog: {reason}",
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
                        "Rezervacija otkazana",
                        $"{patientName} je otkazao/la rezervaciju RES-{entity.Id}.",
                        NotificationTemplate.ReservationCancelled, entity.Id);
                }
            }

            await _context.SaveChangesAsync();
            return _mapper.Map<ReservationResponse>(entity);
        }
    }
 }