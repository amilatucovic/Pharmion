using Pharmion.Model.Enums;

namespace Pharmion.Model.Requests
{
    public class CreatePaymentIntentRequest
    {
        public int ReservationId { get; set; }
        public PaymentMethod Method { get; set; }
    }

    public class PayOnPickupRequest
    {
        public int ReservationId { get; set; }
    }
}