using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class Product
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(200)]
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
        public string? Unit { get; set; }   // tbl, ml, amp...

        public int? PackageSize { get; set; } // npr 30 tbl.

        [Required]
        public decimal Price { get; set; }  

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public string SideEffects { get; set; } = string.Empty;
        
        public string InstructionsForUse { get; set; } = string.Empty;

        public string Contraindications { get; set; } = string.Empty;

        public string? ImageUrl { get; set; } 

        public MedicationDetail? MedicationDetails { get; set; }
        public SupplementDetail? SupplementDetails { get; set; }

        public ICollection<PrescriptionItem> PrescriptionItems { get; set; } = new List<PrescriptionItem>();
        public ICollection<ReservationItem> ReservationItems { get; set; } = new List<ReservationItem>();
        public ICollection<InventoryItem> InventoryItems { get; set; } = new List<InventoryItem>();
    }
}
