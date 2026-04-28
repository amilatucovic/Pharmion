using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pharmion.Services.Database.Entities
{
    public class Pharmacist : User
    {
        [Required]
        public string LicenseNumber { get; set; } = string.Empty;

        [ForeignKey(nameof(Pharmacy))]
        public int PharmacyId { get; set; }
        public Pharmacy Pharmacy { get; set; } = null!;

        public bool IsAdministrator { get; set; } 

        public ICollection<Prescription> Prescriptions { get; set; } = new List<Prescription>();
        public ICollection<DispenseEvent> DispenseEvents { get; set; } = new List<DispenseEvent>();
        public ICollection<EarlyDispenseException> ApprovedEarlyDispenseExceptions { get; set; } = new List<EarlyDispenseException>();

    }
}
