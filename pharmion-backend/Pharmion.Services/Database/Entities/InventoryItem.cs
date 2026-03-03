using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class InventoryItem
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Pharmacy))]
        public int PharmacyId { get; set; }
        public Pharmacy? Pharmacy { get; set; }

        [ForeignKey(nameof(Product))]
        public int ProductId { get; set; }
        public Product? Product { get; set; }

        public int QuantityOnHand { get; set; }
        public int ReservedQuantity { get; set; }
        public int ReorderLevel { get; set; }  

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

        public DateTime ExpirationDate { get; set; }

        public ICollection<StockMovement> StockMovements { get; set; } = new List<StockMovement>();

    }
}

