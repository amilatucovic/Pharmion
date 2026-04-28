using MapsterMapper;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.StateMachines.ReservationStateMachine;

namespace Pharmion.Services.Services.StateMachines.ReservationStateMachine
{
    public class InitialReservationState : BaseReservationState
    {
        public InitialReservationState(IServiceProvider serviceProvider, PharmionDbContext dbContext, IMapper mapper) : base(serviceProvider, dbContext, mapper)
        {
        }

        public override async Task<ReservationResponse> CreateAsync(ReservationInsertRequest request)
        {
            var entity = new Reservation();
            _mapper.Map(request, entity);

            entity.ReservationState = nameof(DraftReservationState);
            entity.CreatedAt = DateTime.UtcNow;

            _context.Reservations.Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<ReservationResponse>(entity);
        }
    }
}
