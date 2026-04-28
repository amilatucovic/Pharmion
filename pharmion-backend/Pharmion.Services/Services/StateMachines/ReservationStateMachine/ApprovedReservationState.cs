using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.StateMachines.ReservationStateMachine;
using System;
using System.Threading.Tasks;

namespace Pharmion.Services.Services.StateMachines.ReservationStateMachine
{
    public class ApprovedReservationState : BaseReservationState
    {
        public ApprovedReservationState(
            IServiceProvider serviceProvider,
            PharmionDbContext context,
            IMapper mapper) : base(serviceProvider, context, mapper)
        {
        }

        public override async Task<ReservationResponse> MarkAsReadyAsync(int id, int pharmacistId)
        {
            var entity = await _context.Reservations
                .Include(r => r.Items)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                throw new UserException("Reservation not found");

            var pharmacist = await _context.Pharmacists.FindAsync(pharmacistId);
            if (pharmacist == null || pharmacist.PharmacyId != entity.PharmacyId)
                throw new UserException("You can only mark reservations from your pharmacy as ready");

            var payment = await _context.Payments
                .FirstOrDefaultAsync(p => p.ReservationId == id
                && (p.Status == PaymentStatus.Pending || p.Status == PaymentStatus.Completed));

            if (payment == null)
                throw new UserException("Patient hasn't selected a payment method yet");

            entity.ReservationState = nameof(ReadyForPickupReservationState);
            entity.ReadyForPickupAt = DateTime.UtcNow;
            entity.PickupDeadline = DateTime.UtcNow.AddHours(48);
            entity.MarkedReadyByPharmacistId = pharmacistId;

            AddNotification(
                             entity.PatientId,
                             "Rezervacija spremna za preuzimanje",
                             $"Vaša rezervacija RES-{entity.Id} je spremna. Preuzmite je do {entity.PickupDeadline:dd.MM.yyyy HH:mm}.",
                             NotificationTemplate.ReservationReadyForPickup, entity.Id);

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

            var patient = await _context.Patients.FindAsync(entity.PatientId);
            var patientName = patient != null ? $"{patient.FirstName} {patient.LastName}" : "Pacijent";

            var pharmacist = await _context.Pharmacists.FindAsync(userId);
            if (pharmacist != null)
            {
                var pharmacistName = $"{pharmacist.FirstName} {pharmacist.LastName}";
                AddNotification(entity.PatientId,
                    "Rezervacija otkazana od strane farmaceuta",
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