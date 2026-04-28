using Pharmion.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class ProductUpdateRequest
    {
        [Required]
        [MaxLength(200, ErrorMessage = "Name must not exceed 200 characters.")]
        public string Name { get; set; } = string.Empty;

        [Required]
        public ProductType Type { get; set; }

        [MaxLength(500)]
        public string? Description { get; set; }

        public bool IsPrescriptionRequired { get; set; }

        public bool IsActive { get; set; } = true;

        [MaxLength(100)]
        public string? SKU { get; set; }

        [MaxLength(100)]
        public string? Barcode { get; set; }

        [MaxLength(150)]
        public string? Manufacturer { get; set; }

        [MaxLength(50)]
        public string? Unit { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Package size must be greater than 0")]
        public int? PackageSize { get; set; }

        [Required]
        [Range(0.01, double.MaxValue, ErrorMessage = "Price must be greater than 0")]
        public decimal Price { get; set; }

        [MaxLength(1000)]
        public string SideEffects { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string InstructionsForUse { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string Contraindications { get; set; } = string.Empty;

        public int? MedicationCategoryId { get; set; }
        public int? PharmacologicalCategoryId { get; set; }
        public string? AtcCode { get; set; }
        public bool RequiresColdChain { get; set; }
        
        public string? TargetGender { get; set; }
        public int? MinAge { get; set; }
        public int? MaxAge { get; set; }
        public string? Tags { get; set; }

    }
}