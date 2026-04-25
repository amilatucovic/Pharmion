using MapsterMapper;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.StateMachines.ReservationStateMachine;
using System;
using System.Threading.Tasks;

namespace Pharmion.Services.Services.StateMachines.ReservationStateMachine
{
    public class CancelledReservationState : BaseReservationState
    {
        public CancelledReservationState(
            IServiceProvider serviceProvider,
            PharmionDbContext context,
            IMapper mapper) : base(serviceProvider, context, mapper)
        {
        }

        public override async Task<ReservationResponse> UpdateAsync(int id, ReservationUpdateRequest request)
        {
            throw new UserException("Cannot modify a cancelled reservation");
        }

        public override async Task<ReservationResponse> SubmitAsync(int id, int patientId)
        {
            throw new UserException("Cannot submit a cancelled reservation");
        }

        public override async Task<ReservationResponse> ApproveAsync(int id, int pharmacistId)
        {
            throw new UserException("Cannot approve a cancelled reservation");
        }

        public override async Task<ReservationResponse> CancelAsync(int id, int userId, string reason)
        {
            throw new UserException("Reservation is already cancelled");
        }

       
    }
}