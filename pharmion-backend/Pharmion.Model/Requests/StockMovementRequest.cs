using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Model.Requests
{
    public class StockMovementRequest
    {
        [Required]
        public int InventoryItemId { get; set; }

        [Required]
        public StockMovementType Type { get; set; }

        [Required]
        [Range(1, int.MaxValue, ErrorMessage = "Quantity must be at least 1.")]
        public int Quantity { get; set; }

        [MaxLength(300)]
        public string? Reason { get; set; }
    }
}
