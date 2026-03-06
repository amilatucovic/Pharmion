using Pharmion.Model.Enums;

namespace Pharmion.Model.Requests
{
    public class PrescriptionItemUpsertRequest
    {
        public int ProductId { get; set; }
        public string Dosage { get; set; } = string.Empty;
        public int QuantityPerPeriod { get; set; }
        public int PeriodDays { get; set; }
        public int Repeats { get; set; }
        public TherapyType TherapyType { get; set; }
    }
}