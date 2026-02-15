using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.Responses
{
    public class MedicationCategoryResponse
    {
        public int Id { get; set; }
        public CategoryCode Code { get; set; }
        public string CodeName { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal PatientPaymentPercentage { get; set; }
        public decimal InsurancePaymentPercentage { get; set; }
        public decimal? FlatFee { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
