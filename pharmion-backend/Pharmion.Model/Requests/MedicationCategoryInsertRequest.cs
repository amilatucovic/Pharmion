using Pharmion.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class MedicationCategoryInsertRequest
    {
        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Code must be a positive number.")]
        public int Code { get; set; }

        [Required]
        [MaxLength(50, ErrorMessage = "Code label must not exceed 50 characters.")]
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
