using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Model.Requests
{
    public class MedicationCategoryInsertRequest
    {
        [Required(ErrorMessage = "Category code is required.")]
        public CategoryCode Code { get; set; }

        [Required]
        [MaxLength(200, ErrorMessage = "Name must not exceed 200 characters.")]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500, ErrorMessage = "Description must not exceed 500 characters.")]
        public string Description { get; set; } = string.Empty;

        [Required]
        [Range(0, 100, ErrorMessage = "Patient payment percentage must be between 0 and 100.")]
        public decimal PatientPaymentPercentage { get; set; }

        [Required]
        [Range(0, 100, ErrorMessage = "Insurance payment percentage must be between 0 and 100.")]
        public decimal InsurancePaymentPercentage { get; set; }

        [Range(0, double.MaxValue, ErrorMessage = "Flat fee must be a positive value.")]
        public decimal? FlatFee { get; set; }
    }
}
