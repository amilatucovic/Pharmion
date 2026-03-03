using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class TherapySchedule
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Patient))]
        public int PatientId { get; set; }
        public Patient? Patient { get; set; }

        [ForeignKey(nameof(Product))]
        public int ProductId { get; set; }
        public Product? Product { get; set; }

        
        [ForeignKey(nameof(PrescriptionItem))]
        public int? PrescriptionItemId { get; set; }
        public PrescriptionItem? PrescriptionItem { get; set; }

        [MaxLength(100)]
        public string DoseText { get; set; } = String.Empty; // "1 tablet", "2 kapsule", "5 ml" 

        [MaxLength(200)]
        public string InstructionText { get; set; } = String.Empty; // "uz obrok", "prije spavanja", "svakih 8 sati"

        public DateTime StartDate { get; set; } = DateTime.UtcNow.Date;
        public DateTime? EndDate { get; set; } // null = trajno dok se ne deaktivira

        public bool IsActive { get; set; } = true;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public ICollection<TherapyScheduleTime> Times { get; set; } = new List<TherapyScheduleTime>();
        public ICollection<TherapyReminder> Reminders { get; set; } = new List<TherapyReminder>();
    }
}
