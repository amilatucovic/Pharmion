using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.Responses
{
    public class ProductResponse
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public ProductType Type { get; set; }
        public string TypeName { get; set; } 
        public bool IsPrescriptionRequired { get; set; }
        public bool IsActive { get; set; }
        public string? SKU { get; set; }
        public string? Barcode { get; set; }
        public string? Manufacturer { get; set; }
        public string? Unit { get; set; }
        public int? PackageSize { get; set; }
        public decimal Price { get; set; }
        public string SideEffects { get; set; }
        public string InstructionsForUse { get; set; }
        public string Contraindications { get; set; }
        public string? ImageUrl { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
        public int? MedicationCategoryId { get; set; }
        public string? MedicationCategoryName { get; set; }
        public int? PharmacologicalCategoryId { get; set; }
        public string? PharmacologicalCategoryName { get; set; }
        public string? AtcCode { get; set; }
        public bool RequiresColdChain { get; set; }
        public string? TargetGender { get; set; }
        public int? MinAge { get; set; }
        public int? MaxAge { get; set; }
        public string? Tags { get; set; }
    }
}