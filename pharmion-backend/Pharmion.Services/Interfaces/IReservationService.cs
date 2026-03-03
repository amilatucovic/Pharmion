using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface IReservationService : ICRUDService<ReservationResponse, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest>
    {
        // State Machine akcije
        Task<ReservationResponse> SubmitAsync(int reservationId, int patientId);
        Task<ReservationResponse> ApproveAsync(int reservationId, int pharmacistId);
        Task<ReservationResponse> RejectAsync(int reservationId, int pharmacistId, string reason);
        Task<ReservationResponse> MarkAsReadyAsync(int reservationId, int pharmacistId);
        Task<ReservationResponse> MarkAsPickedUpAsync(int reservationId, int pharmacistId);
        Task<ReservationResponse> CancelAsync(int reservationId, int userId, string reason);
        Task<ReservationResponse> AddToReservationAsync(int patientId, AddToReservationRequest request);

        // Helper metode
        Task<List<string>> GetAllowedActionsAsync(int reservationId);
        Task<List<ReservationResponse>> GetReservationsByPatientAsync(int patientId);
        Task<List<ReservationResponse>> GetReservationsByPharmacyAsync(int pharmacyId);

        Task<List<ReservationItemResponse>> GetItemsAsync(int reservationId, int patientId);
        Task<ReservationItemResponse> AddItemAsync(int reservationId, int patientId, ReservationItemInsertRequest request);
        Task<ReservationItemResponse> UpdateItemAsync(int reservationId, int itemId, int patientId, ReservationItemUpdateRequest request);
        Task DeleteItemAsync(int reservationId, int itemId, int patientId);
    }
}