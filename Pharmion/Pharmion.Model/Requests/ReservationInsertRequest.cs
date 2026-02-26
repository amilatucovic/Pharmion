using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class ReservationInsertRequest
    {
        [Required]
        public int PatientId { get; set; }

        [Required]
        public int PharmacyId { get; set; }

        // Items se dodaju zasebno ili kroz nested objekat
        // public List<ReservationItemRequest> Items { get; set; }
    }
}