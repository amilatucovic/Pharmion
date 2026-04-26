using System;
using System.Collections.Generic;

namespace Pharmion.Model.Responses
{
    public class ReservationResponse
    {
        public int Id { get; set; }
        public int PatientId { get; set; }
        public string PatientName { get; set; }
        public int PharmacyId { get; set; }
        public string PharmacyName { get; set; }
        public string ReservationState { get; set; }
        public string ReservationStateDisplay { get; set; } 
        public string PatientEmail { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public DateTime? SubmittedAt { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public DateTime? ReadyForPickupAt { get; set; }
        public DateTime? PickedUpAt { get; set; }
        public decimal TotalAmount { get; set; }
        public decimal PatientPaysAmount { get; set; }
        public decimal InsurancePaysAmount { get; set; }
        public DateTime? PickupDeadline { get; set; }
        public List<ReservationItemResponse> Items { get; set; }
        public bool IsPaid { get; set; }
        public string? PaymentMethod { get; set; }
        public List<string> AllowedActions { get; set; }
        public string? CancellationReason { get; set; }
        public DateTime? CancelledAt { get; set; }
        public int? CancelledByUserId { get; set; }
        public string? RejectionReason { get; set; }
        public DateTime? RejectedAt { get; set; }
        public int? RejectedByPharmacistId { get; set; }
        public int? ApprovedByPharmacistId { get; set; }
        public int? MarkedReadyByPharmacistId { get; set; }
        public int? MarkedPickedUpByPharmacistId { get; set; }
        public bool IsRefunded { get; set; }
        public bool HasEarlyDispenseException { get; set; }
        public int? EarlyDispenseExceptionStatus { get; set; }
    }
}