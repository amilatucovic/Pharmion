using System;
using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class InventoryItemUpdateRequest
    {
        [Required]
        [Range(0, int.MaxValue, ErrorMessage = "Quantity on hand must be 0 or greater.")]
        public int QuantityOnHand { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "Reorder level must be 0 or greater.")]
        public int ReorderLevel { get; set; }

        [Required(ErrorMessage = "Expiration date is required.")]
        public DateTime ExpirationDate { get; set; }
    }
}
