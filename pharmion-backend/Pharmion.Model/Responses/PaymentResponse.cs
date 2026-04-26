using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.Responses
{
    public class PaymentResponse
    {
        public int Id { get; set; }
        public int ReservationId { get; set; }
        public PaymentMethod Method { get; set; }
        public string MethodDisplay { get; set; } = string.Empty;
        public PaymentStatus Status { get; set; }
        public string StatusDisplay { get; set; } = string.Empty;
        public decimal Amount { get; set; }          // u KM
        public decimal AmountInEur { get; set; }     // u EUR za Stripe
        public string Currency { get; set; } = "EUR";
        public string? ClientSecret { get; set; }
        public string? StripePaymentIntentId { get; set; }
        public bool IsPaid { get; set; }
        public bool IsRefunded { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? PaidAt { get; set; }
        public DateTime? RefundedAt { get; set; }
        public string? RefundReason { get; set; }
        public int? ProcessedByPharmacistId { get; set; }
    }
}