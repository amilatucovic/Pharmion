using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.StateMachines.ReservationStateMachine;


namespace Pharmion.Services.Services.StateMachines.ReservationStateMachine
{
    public class ReadyForPickupReservationState : BaseReservationState
    {
        public ReadyForPickupReservationState(
            IServiceProvider serviceProvider,
            PharmionDbContext context,
            IMapper mapper) : base(serviceProvider, context, mapper)
        {
        }

        public override async Task<ReservationResponse> MarkAsPickedUpAsync(int id, int pharmacistId)
        {
            var entity = await _context.Reservations
                .Include(r => r.Items)
                    .ThenInclude(ri => ri.Product)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                throw new UserException("Reservation not found");

            var payment = await _context.Payments
                   .FirstOrDefaultAsync(p => p.ReservationId == id);

            if (payment != null &&
                payment.Method == PaymentMethod.PayOnPickup &&
                payment.Status != PaymentStatus.Completed)
                throw new UserException("Cannot mark as picked up: cash payment has not been confirmed yet.");

            var pharmacist = await _context.Pharmacists.FindAsync(pharmacistId);
            if (pharmacist == null || pharmacist.PharmacyId != entity.PharmacyId)
                throw new UserException("You can only dispense reservations from your pharmacy");

            await DispenseInventoryAsync(entity);

            foreach (var item in entity.Items)
            {
                var dispenseEvent = new DispenseEvent
                {
                    ReservationId = entity.Id,
                    PrescriptionItemId = item.PrescriptionItemId,
                    DispensedAt = DateTime.UtcNow,
                    Quantity = item.Quantity,
                    DispensedByPharmacistId = pharmacistId
                };
                _context.DispenseEvents.Add(dispenseEvent);
            }

            foreach (var item in entity.Items.Where(i => i.PrescriptionItemId.HasValue))
            {
                var prescriptionItem = await _context.PrescriptionItems
                    .FindAsync(item.PrescriptionItemId!.Value);

                if (prescriptionItem != null)
                {
                    prescriptionItem.RepeatsUsed += 1;
                    prescriptionItem.LastDispensedAt = DateTime.UtcNow;
                    prescriptionItem.NextEligibleDispenseAt = DateTime.UtcNow.AddDays(prescriptionItem.PeriodDays - 1);
                }
            }

            entity.ReservationState = nameof(PickedUpReservationState);
            entity.PickedUpAt = DateTime.UtcNow;
            entity.MarkedPickedUpByPharmacistId = pharmacistId;

            await _context.SaveChangesAsync();
            return _mapper.Map<ReservationResponse>(entity);
        }

        public override async Task<ReservationResponse> CancelAsync(int id, int userId, string reason)
        {
            var entity = await _context.Reservations.FindAsync(id);
            if (entity == null)
                throw new UserException("Reservation not found");

            if (entity.PickupDeadline.HasValue && DateTime.UtcNow > entity.PickupDeadline.Value)
            {
                reason = $"Pickup deadline expired. {reason}";
            }

            await ReturnReservedInventoryAsync(entity);
            await HandleStripeRefundOnCancelAsync(id);

            entity.ReservationState = nameof(CancelledReservationState);
            entity.CancellationReason = reason;      
            entity.CancelledAt = DateTime.UtcNow;   
            entity.CancelledByUserId = userId;
            var pharmacist = await _context.Pharmacists.FindAsync(userId);
            
            if (pharmacist != null)
            {
                var pharmacistName = $"{pharmacist.FirstName} {pharmacist.LastName}";
                AddNotification(entity.PatientId,
                    "Reservation cancelled by pharmacist",
                    $"Pharmacist {pharmacistName} has cancelled your reservation RES-{entity.Id}. Reason: {reason}",
                NotificationTemplate.ReservationCancelledByPharmacist, entity.Id);
            }
            

            await _context.SaveChangesAsync();

            return _mapper.Map<ReservationResponse>(entity);
        }
    }
}