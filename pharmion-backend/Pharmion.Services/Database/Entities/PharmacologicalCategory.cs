using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Entities
{
    public class PharmacologicalCategory
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(100)]
        public string Code { get; set; } = string.Empty; 

        [Required, MaxLength(200)]
        public string Name { get; set; } = string.Empty; 

        [MaxLength(500)]
        public string Description { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        
        public ICollection<MedicationDetail> MedicationDetails { get; set; } = new List<MedicationDetail>();
    }
}
