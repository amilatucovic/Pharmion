using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.StateMachines.ReservationStateMachine
{
    public class DraftReservationState : BaseReservationState
    {
        public DraftReservationState(
            IServiceProvider serviceProvider,
            PharmionDbContext context,
            IMapper mapper) : base(serviceProvider, context, mapper)
        {
        }

        public override async Task<ReservationResponse> UpdateAsync(int id, ReservationUpdateRequest request)
        {
            var entity = await _context.Reservations.FindAsync(id);
            if (entity == null)
                throw new UserException("Reservation not found");

            _mapper.Map(request, entity);
            entity.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return _mapper.Map<ReservationResponse>(entity);
        }

        public override async Task<ReservationResponse> SubmitAsync(int id, int patientId)
        {
            var entity = await _context.Reservations
                .Include(r => r.Items) 
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                throw new UserException("Reservation not found");

            if (entity.PatientId != patientId)
                throw new UserException("You can only submit your own reservations");

            if (!entity.Items.Any())
                throw new UserException("Cannot submit empty reservation");

            await ReserveInventoryAsync(entity);

            entity.ReservationState = nameof(SubmittedReservationState);
            entity.SubmittedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();

            return _mapper.Map<ReservationResponse>(entity);
        }

        public override async Task<ReservationResponse> CancelAsync(int id, int userId, string reason)
        {
            var entity = await _context.Reservations.FindAsync(id);
            if (entity == null)
                throw new UserException("Reservation not found");

            entity.ReservationState = nameof(CancelledReservationState);
            await _context.SaveChangesAsync();

            return _mapper.Map<ReservationResponse>(entity);
        }
    }
}