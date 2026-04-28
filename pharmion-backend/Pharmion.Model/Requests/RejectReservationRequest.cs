using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class RejectReservationRequest
    {
        [Required]
        [MaxLength(500)]
        public string Reason { get; set; }
    }
}
