using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.Responses
{
    public class StockMovementResponse
    {
        public int Id { get; set; }
        public int InventoryItemId { get; set; }
        public StockMovementType Type { get; set; }
        public string TypeName { get; set; } = string.Empty;
        public int Quantity { get; set; }
        public string? Reason { get; set; }
        public DateTime CreatedAt { get; set; }
        public string? CreatedByPharmacistName { get; set; }
    }
}
