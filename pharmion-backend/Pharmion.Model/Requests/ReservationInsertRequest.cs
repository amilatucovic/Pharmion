using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class ReservationInsertRequest
    {
        [Required]
        public int PatientId { get; set; }

        [Required]
        public int PharmacyId { get; set; }

    }
}