using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;

namespace Pharmion.Services.StateMachines.ReservationStateMachine
{
    public abstract class BaseReservationState
    {
        protected readonly IServiceProvider _serviceProvider;
        protected readonly PharmionDbContext _context;
        protected readonly IMapper _mapper;
        

        public BaseReservationState(
            IServiceProvider serviceProvider,
            PharmionDbContext context,
            IMapper mapper)
        {
            _serviceProvider = serviceProvider;
            _context = context;
            _mapper = mapper;
           
        }


        public virtual async Task<ReservationResponse> CreateAsync(ReservationInsertRequest request)
        {
            throw new UserException("Not allowed in this state");
        }

        public virtual async Task<ReservationResponse> UpdateAsync(int id, ReservationUpdateRequest request)
        {
            throw new UserException("Cannot modify reservation in current state");
        }

        public virtual async Task<ReservationResponse> SubmitAsync(int id, int patientId)
        {
            throw new UserException("Cannot submit reservation in current state");
        }

        public virtual async Task<ReservationResponse> ApproveAsync(int id, int pharmacistId)
        {
            throw new UserException("Cannot approve reservation in current state");
        }

        public virtual async Task<ReservationResponse> RejectAsync(int id, int pharmacistId, string reason)
        {
            throw new UserException("Cannot reject reservation in current state");
        }

        public virtual async Task<ReservationResponse> MarkAsReadyAsync(int id, int pharmacistId)
        {
            throw new UserException("Cannot mark as ready in current state");
        }

        public virtual async Task<ReservationResponse> MarkAsPickedUpAsync(int id, int pharmacistId)
        {
            throw new UserException("Cannot mark as picked up in current state");
        }

        public virtual async Task<ReservationResponse> CancelAsync(int id, int userId, string reason)
        {
            throw new UserException("Cannot cancel reservation in current state");
        }

       
        public BaseReservationState GetReservationState(string stateName)
        {
            switch (stateName)
            {
                case nameof(InitialReservationState):
                    var initialState = _serviceProvider.GetService<InitialReservationState>();
                    if(initialState == null)
                        throw new Exception($"State {stateName} not registered in DI");
                    return initialState;

                case nameof(DraftReservationState):
                   var draftState = _serviceProvider.GetService<DraftReservationState>();
                    if (draftState == null)
                        throw new Exception($"State {stateName} not registered in DI");
                    return draftState;

                case nameof(SubmittedReservationState):
                    var submittedState = _serviceProvider.GetService<SubmittedReservationState>();
                    if (submittedState == null)
                        throw new Exception($"State {stateName} not registered in DI");
                    return submittedState;

                case nameof(ApprovedReservationState):
                    var approvedState = _serviceProvider.GetService<ApprovedReservationState>();
                    if (approvedState == null)
                        throw new Exception($"State {stateName} not registered in DI");
                    return approvedState;

                case nameof(ReadyForPickupReservationState):
                    var readyForPickupState = _serviceProvider.GetService<ReadyForPickupReservationState>();
                    if (readyForPickupState == null)
                        throw new Exception($"State {stateName} not registered in DI");
                    return readyForPickupState;

                case nameof(PickedUpReservationState):
                    var pickedUpState = _serviceProvider.GetService<PickedUpReservationState>();
                    if (pickedUpState == null)
                        throw new Exception($"State {stateName} not registered in DI");
                    return pickedUpState;

                case nameof(CancelledReservationState):
                    var cancelledState = _serviceProvider.GetService<CancelledReservationState>();
                    if (cancelledState == null)
                        throw new Exception($"State {stateName} not registered in DI");
                    return cancelledState;

                case nameof(RejectedReservationState):
                    var rejectedState = _serviceProvider.GetService<RejectedReservationState>();
                    if (rejectedState == null)
                        throw new Exception($"State {stateName} not registered in DI");
                    return rejectedState;

                default:
                    throw new Exception($"State {stateName} not defined");
            }
        }

        protected async Task ReserveInventoryAsync(Reservation reservation)
        {
            foreach (var item in reservation.Items)
            {
                var inventoryItem = await _context.InventoryItems
                    .FirstOrDefaultAsync(i => i.PharmacyId == reservation.PharmacyId && i.ProductId == item.ProductId);

                if (inventoryItem == null)
                    throw new UserException($"Product not available in this pharmacy");

               
                var availableQuantity = inventoryItem.QuantityOnHand - inventoryItem.ReservedQuantity;

                if (availableQuantity < item.Quantity)
                    throw new UserException($"Insufficient stock. Available: {availableQuantity}");

                inventoryItem.ReservedQuantity += item.Quantity;
            }

            
        }

        protected async Task ReturnReservedInventoryAsync(Reservation reservation)
        {
            foreach (var item in reservation.Items)
            {
                var inventoryItem = await _context.InventoryItems
                    .FirstOrDefaultAsync(i => i.PharmacyId == reservation.PharmacyId && i.ProductId == item.ProductId);

                if (inventoryItem != null)
                {
                    inventoryItem.ReservedQuantity -= item.Quantity;

                    if (inventoryItem.ReservedQuantity < 0)
                        inventoryItem.ReservedQuantity = 0;
                }
            }

           
        }

        protected async Task DispenseInventoryAsync(Reservation reservation)
        {
            foreach (var item in reservation.Items)
            {
                var inventoryItem = await _context.InventoryItems
                    .FirstOrDefaultAsync(i => i.PharmacyId == reservation.PharmacyId && i.ProductId == item.ProductId);

                if (inventoryItem != null)
                {
                    inventoryItem.QuantityOnHand -= item.Quantity;

                    inventoryItem.ReservedQuantity -= item.Quantity;

                    
                    if (inventoryItem.QuantityOnHand < 0)
                        throw new UserException($"Negative inventory for product {item.ProductId}");

                    if (inventoryItem.ReservedQuantity < 0)
                        inventoryItem.ReservedQuantity = 0;

                    inventoryItem.UpdatedAt = DateTime.UtcNow;
                }
            }

            
        }

        protected void AddNotification(int userId, string title, string message, NotificationTemplate template, int? reservationId = null)
        {
              _context.Notifications.Add(new Notification
              {
                   UserId = userId,
                   Title = title,
                   Message = message,
                   Template = template,
                   Type = NotificationType.InApp,
                   IsRead = false,
                   CreatedAt = DateTime.UtcNow,
                   ReservationId = reservationId
              });
        }
    }
}