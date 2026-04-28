using MapsterMapper;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.StateMachines.ReservationStateMachine;

namespace Pharmion.Services.Services.StateMachines.ReservationStateMachine
{
    public class PickedUpReservationState : BaseReservationState
    {
        public PickedUpReservationState(
            IServiceProvider serviceProvider,
            PharmionDbContext context,
            IMapper mapper) : base(serviceProvider, context, mapper)
        {
        }


        public override async Task<ReservationResponse> UpdateAsync(int id, ReservationUpdateRequest request)
        {
            throw new UserException("Cannot modify a picked up reservation");
        }

        public override async Task<ReservationResponse> SubmitAsync(int id, int patientId)
        {
            throw new UserException("Reservation already picked up");
        }

        public override async Task<ReservationResponse> ApproveAsync(int id, int pharmacistId)
        {
            throw new UserException("Reservation already picked up");
        }

        public override async Task<ReservationResponse> CancelAsync(int id, int userId, string reason)
        {
            throw new UserException("Cannot cancel a picked up reservation");
        }
    }
}