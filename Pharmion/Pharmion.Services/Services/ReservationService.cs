using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;
using Pharmion.Services.StateMachines.ReservationStateMachine;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class ReservationService : BaseCRUDService<ReservationResponse, ReservationSearchObject, Reservation, ReservationInsertRequest, ReservationUpdateRequest>, IReservationService
    {
        private readonly PharmionDbContext _context;
        private readonly IServiceProvider _serviceProvider;

        public ReservationService(
            PharmionDbContext context,
            IMapper mapper,
            IServiceProvider serviceProvider) : base(context, mapper)
        {
            _context = context;
            _serviceProvider = serviceProvider;
        }

        public override async Task<ReservationResponse> CreateAsync(ReservationInsertRequest request)
        {
            var initialState = _serviceProvider.GetService(typeof(InitialReservationState)) as InitialReservationState;
            if (initialState == null)
                throw new Exception("InitialReservationState not registered in DI");

            return await initialState.CreateAsync(request);
        }

        public override async Task<ReservationResponse> UpdateAsync(int id, ReservationUpdateRequest request)
        {
            var reservation = await _context.Reservations.FindAsync(id);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);

            return await currentState.UpdateAsync(id, request);
        }


        public async Task<ReservationResponse> SubmitAsync(int reservationId, int patientId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            return await currentState.SubmitAsync(reservationId, patientId);
        }

        public async Task<ReservationResponse> ApproveAsync(int reservationId, int pharmacistId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            return await currentState.ApproveAsync(reservationId, pharmacistId);
        }

        public async Task<ReservationResponse> RejectAsync(int reservationId, int pharmacistId, string reason)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            return await currentState.RejectAsync(reservationId, pharmacistId, reason);
        }

        public async Task<ReservationResponse> MarkAsReadyAsync(int reservationId, int pharmacistId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            return await currentState.MarkAsReadyAsync(reservationId, pharmacistId);
        }

        public async Task<ReservationResponse> MarkAsPickedUpAsync(int reservationId, int pharmacistId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            return await currentState.MarkAsPickedUpAsync(reservationId, pharmacistId);
        }

        public async Task<ReservationResponse> CancelAsync(int reservationId, int userId, string reason)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            return await currentState.CancelAsync(reservationId, userId, reason);
        }


        public async Task<List<string>> GetAllowedActionsAsync(int reservationId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var allowedActions = new List<string>();

            switch (reservation.ReservationState)
            {
                case nameof(DraftReservationState):
                    allowedActions.AddRange(new[] { "Submit", "Update", "Cancel" });
                    break;

                case nameof(SubmittedReservationState):
                    allowedActions.AddRange(new[] { "Approve", "Reject", "Cancel" });
                    break;

                case nameof(ApprovedReservationState):
                    allowedActions.AddRange(new[] { "MarkAsReady", "Cancel" });
                    break;

                case nameof(ReadyForPickupReservationState):
                    allowedActions.AddRange(new[] { "MarkAsPickedUp", "Cancel" });
                    break;

                case nameof(PickedUpReservationState):
                case nameof(CancelledReservationState):
                case nameof(RejectedReservationState):
                    break;
            }

            return allowedActions;
        }

        public async Task<List<ReservationResponse>> GetReservationsByPatientAsync(int patientId)
        {
            var reservations = await _context.Reservations
                .Include(r => r.Items)
                    .ThenInclude(ri => ri.Product)
                .Include(r => r.Pharmacy)
                .Where(r => r.PatientId == patientId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return _mapper.Map<List<ReservationResponse>>(reservations);
        }

        public async Task<List<ReservationResponse>> GetReservationsByPharmacyAsync(int pharmacyId)
        {
            var reservations = await _context.Reservations
                .Include(r => r.Items)
                    .ThenInclude(ri => ri.Product)
                .Include(r => r.Patient)
                .Where(r => r.PharmacyId == pharmacyId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return _mapper.Map<List<ReservationResponse>>(reservations);
        }

        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            if (search.PatientId.HasValue)
            {
                query = query.Where(r => r.PatientId == search.PatientId.Value);
            }

            if (search.PharmacyId.HasValue)
            {
                query = query.Where(r => r.PharmacyId == search.PharmacyId.Value);
            }

            if (!string.IsNullOrEmpty(search.ReservationState))
            {
                query = query.Where(r => r.ReservationState == search.ReservationState);
            }

            if (search.CreatedFrom.HasValue)
            {
                query = query.Where(r => r.CreatedAt >= search.CreatedFrom.Value);
            }

            if (search.CreatedTo.HasValue)
            {
                query = query.Where(r => r.CreatedAt <= search.CreatedTo.Value);
            }

            return query;
        }

        private BaseReservationState GetCurrentState(string stateName)
        {
            
            var baseState = _serviceProvider.GetService(typeof(DraftReservationState)) as BaseReservationState;
            if (baseState == null)
                throw new Exception("State machine not properly configured");

            return baseState.GetReservationState(stateName);
        }
    }
}