namespace Pharmion.Model.Responses
{
    public class ReservationItemResponse
    {
        public int Id { get; set; }
        public int ReservationId { get; set; }
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string ProductType { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public decimal UnitPrice { get; set; }
        public decimal LineTotal { get; set; }
        public decimal PatientPart { get; set; }
        public decimal InsurancePart { get; set; }
        public int? PrescriptionItemId { get; set; }
        public bool IsSubstitutionAllowed { get; set; }
        public bool RequiresPrescription { get; set; }
    }
}