namespace Pharmion.Model.Messages
{
    public class ReservationRejectedMessage
    {
        public int ReservationId { get; set; }
        public string PatientEmail { get; set; } = string.Empty;
        public string PatientName { get; set; } = string.Empty;
        public string PharmacyName { get; set; } = string.Empty;
        public string Reason { get; set; } = string.Empty;
    }
}
