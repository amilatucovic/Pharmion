using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class Payment
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Reservation))]
        public int ReservationId { get; set; }
        public Reservation? Reservation { get; set; }

        public PaymentMethod Method { get; set; }


        public PaymentStatus Status { get; set; } = PaymentStatus.Pending;

        public decimal Amount { get; set; }

        [MaxLength(10)]
        public string Currency { get; set; } = "BAM";

        [MaxLength(200)]
        public string? StripePaymentIntentId { get; set; }

        [MaxLength(200)]
        public string? StripeSessionId { get; set; }
        public int? ProcessedByPharmacistId { get; set; }  
        public string? RefundReason { get; set; }
        public DateTime? RefundedAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? PaidAt { get; set; }
    }
}
