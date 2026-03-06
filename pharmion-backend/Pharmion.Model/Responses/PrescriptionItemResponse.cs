using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.Responses
{
    public class PrescriptionItemResponse
    {
        public int Id { get; set; }
        public int PrescriptionId { get; set; }
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string Dosage { get; set; } = string.Empty;
        public int QuantityPerPeriod { get; set; }
        public int PeriodDays { get; set; }
        public int Repeats { get; set; }
        public int RepeatsUsed { get; set; }
        public TherapyType TherapyType { get; set; }
        public string TherapyTypeDisplay { get; set; } = string.Empty;
        public DateTime? LastDispensedAt { get; set; }
        public DateTime? NextEligibleDispenseAt { get; set; }
    }
}