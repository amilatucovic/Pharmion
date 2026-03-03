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
        public List<string> AllowedActions { get; set; } 
    }
}