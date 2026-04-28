using System;

namespace Pharmion.Model.Messages
{
    public class ReservationReadyMessage
    {
        public int ReservationId { get; set; }
        public string PatientEmail { get; set; } = string.Empty;
        public string PatientName { get; set; } = string.Empty;
        public string PharmacyName { get; set; } = string.Empty;
        public DateTime? PickupDeadline { get; set; }
    }
}
