using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;
using System;
using System.Threading.Tasks;

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
            await _context.SaveChangesAsync();

            return _mapper.Map<ReservationResponse>(entity);
        }
    }
}