using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class ReservationItemInsertRequest
    {
        [Required]
        public int ProductId { get; set; }

        [Required, Range(1, 999)]
        public int Quantity { get; set; }

        public int? PrescriptionItemId { get; set; }
    }
}