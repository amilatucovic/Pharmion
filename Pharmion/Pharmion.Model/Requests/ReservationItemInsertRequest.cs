using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class ReservationItemInsertRequest
    {
        [Required]
        public int ProductId { get; set; }

        [Required, Range(1, 999)]
        public int Quantity { get; set; }

        // Null za suplemente i OTC, obavezno za lijekove na recept
        public int? PrescriptionItemId { get; set; }
    }
}