using System.ComponentModel.DataAnnotations;

namespace Pharmion.Services.Database.Entities
{
    public class ChronicDisease
    {
        [Key]
        public int Id { get; set; }

        [Required, MaxLength(50)]
        public string Code { get; set; } = string.Empty;

        [Required, MaxLength(150)]
        public string Name { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }

        public ICollection<PatientChronicDisease> PatientChronicDiseases { get; set; } = new List<PatientChronicDisease>();

    }
}
