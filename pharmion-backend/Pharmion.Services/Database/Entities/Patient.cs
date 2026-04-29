using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pharmion.Services.Database.Entities
{
    public class Patient : User
    {
        public DateTime DateOfBirth { get; set; }

        [MaxLength(13)]
        public string JMBG { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? InsuranceNumber { get; set; }

        public string Address { get; set; } = string.Empty;

        [ForeignKey(nameof(City))]
        public int CityId { get; set; }
        public City? City { get; set; }

        public string PhoneNumber { get; set; } = string.Empty;
        public string EmergencyContact { get; set; } = string.Empty;
        public bool IsInsured { get; set; }
        

        public ICollection<PatientChronicDisease> ChronicDiseases { get; set; } = new List<PatientChronicDisease>();
        public ICollection<Prescription> Prescriptions { get; set; } = new List<Prescription>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();

    }
}
