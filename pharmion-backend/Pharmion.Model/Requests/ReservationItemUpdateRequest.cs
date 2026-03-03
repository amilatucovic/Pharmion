using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class ReservationItemUpdateRequest
    {
        [Required, Range(1, 999)]
        public int Quantity { get; set; }

       
    }
}