using Pharmion.Model.Enums;
using System.ComponentModel.DataAnnotations;

namespace Pharmion.Services.Database.Entities
{
    public class MedicationCategory
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public CategoryCode Code { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;

        [Required]
        public decimal PatientPaymentPercentage { get; set; }

        [Required]
        public decimal InsurancePaymentPercentage { get; set; }
        public decimal? FlatFee { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
    }
}
