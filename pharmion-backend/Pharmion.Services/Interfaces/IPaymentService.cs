using Pharmion.Model.Requests;
using Pharmion.Model.Responses;

namespace Pharmion.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<PaymentResponse> CreatePaymentIntentAsync(int patientId, CreatePaymentIntentRequest request);
        Task<PaymentResponse> HandleWebhookAsync(string payload, string stripeSignature);
        Task<PaymentResponse> ProcessPayOnPickupAsync(int pharmacistId, int reservationId);
        Task<PaymentResponse> RefundAsync(int reservationId, int userId, string userRole, int? pharmacyId);
        Task<PaymentResponse?> GetByReservationIdAsync(int reservationId, int userId, string userRole, int? pharmacyId);
        Task<PaymentResponse> CheckStripeStatusAsync(int patientId, int reservationId);
    }
}