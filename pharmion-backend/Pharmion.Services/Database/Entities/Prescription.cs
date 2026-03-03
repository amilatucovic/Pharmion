using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class Prescription
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Patient))]
        public int PatientId { get; set; }
        public Patient? Patient { get; set; }

        [ForeignKey(nameof(CreatedByPharmacist))]
        public int CreatedByPharmacistId { get; set; }
        public Pharmacist? CreatedByPharmacist { get; set; }

        [Required, MaxLength(200)]
        public string DoctorName { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? Facility { get; set; } // Dom zdravlja Mostar ili KB "Dr. Safet Mujić" Mostar

        public DateTime IssuedAt { get; set; } = DateTime.UtcNow;
        public DateTime? ValidFrom { get; set; }
        public DateTime? ValidTo { get; set; }

        public PrescriptionStatus Status { get; set; } = PrescriptionStatus.Active;

        [MaxLength(500)]
        public string? Notes { get; set; }

        public ICollection<PrescriptionItem> Items { get; set; } = new List<PrescriptionItem>();
    }
}
