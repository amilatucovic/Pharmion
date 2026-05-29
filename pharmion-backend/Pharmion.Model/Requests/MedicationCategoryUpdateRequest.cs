using System;
using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class MedicationCategoryUpdateRequest
    {
        [Required]
        [MaxLength(50)]
        public string CodeLabel { get; set; } = string.Empty;

        [Required]
        [MaxLength(200)]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;

        [Required]
        [Range(0, 100)]
        public decimal PatientPaymentPercentage { get; set; }

        [Required]
        [Range(0, 100)]
        public decimal InsurancePaymentPercentage { get; set; }

        [Range(0, double.MaxValue)]
        public decimal? FlatFee { get; set; }
    }
}
