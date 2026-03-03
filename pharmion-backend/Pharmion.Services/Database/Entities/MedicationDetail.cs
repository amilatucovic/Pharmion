using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class MedicationDetail
    {
        [Key, ForeignKey(nameof(Product))]
        public int ProductId { get; set; }
        public Product? Product { get; set; }

        [MaxLength(50)]
        public string? ATCCode { get; set; }

        public bool RequiresColdChain { get; set; }

        [ForeignKey(nameof(MedicationCategory))]
        public int MedicationCategoryId { get; set; }
        public MedicationCategory? MedicationCategory { get; set; }

        [ForeignKey(nameof(PharmacologicalCategory))]
        public int? PharmacologicalCategoryId { get; set; }
        public PharmacologicalCategory? PharmacologicalCategory { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.Now;
        public DateTime? UpdatedAt { get; set; }
    }
}
