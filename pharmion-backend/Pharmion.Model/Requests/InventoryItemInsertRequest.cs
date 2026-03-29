using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Model.Requests
{
    public class InventoryItemInsertRequest
    {
        [Required(ErrorMessage = "Pharmacy is required.")]
        public int PharmacyId { get; set; }

        [Required(ErrorMessage = "Product is required.")]
        public int ProductId { get; set; }

        [Required]
        [Range(0, int.MaxValue, ErrorMessage = "Quantity on hand must be 0 or greater.")]
        public int QuantityOnHand { get; set; }

        [Range(0, int.MaxValue, ErrorMessage = "Reorder level must be 0 or greater.")]
        public int ReorderLevel { get; set; } = 10;

        [Required(ErrorMessage = "Expiration date is required.")]
        public DateTime ExpirationDate { get; set; }
    }
}
