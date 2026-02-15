using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class PatientChronicDisease
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Patient))]
        public int PatientId { get; set; }
        public Patient? Patient { get; set; }

        [ForeignKey(nameof(ChronicDisease))]
        public int ChronicDiseaseId { get; set; }
        public ChronicDisease? ChronicDisease { get; set; }

        public DateTime DiagnosedAt { get; set; } = DateTime.UtcNow;
        public string Notes { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
