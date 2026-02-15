using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class StockMovement
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(InventoryItem))]
        public int InventoryItemId { get; set; }
        public InventoryItem? InventoryItem { get; set; }

        public StockMovementType Type { get; set; }
        public int Quantity { get; set; }

        [MaxLength(300)]
        public string? Reason { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey(nameof(CreatedByPharmacist))]
        public int? CreatedByPharmacistId { get; set; }
        public Pharmacist? CreatedByPharmacist { get; set; }
    }
}
