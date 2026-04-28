using System;

namespace Pharmion.Model.Responses
{
    public class InventoryItemResponse
    {
        public int Id { get; set; }
        public int PharmacyId { get; set; }
        public string PharmacyName { get; set; } = string.Empty;
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string? ProductSku { get; set; }
        public string? ProductImageUrl { get; set; }
        public int QuantityOnHand { get; set; }
        public int ReservedQuantity { get; set; }
        public int AvailableQuantity => QuantityOnHand - ReservedQuantity;
        public int ReorderLevel { get; set; }
        public bool IsLowStock => AvailableQuantity <= ReorderLevel;
        public DateTime ExpirationDate { get; set; }
        public bool IsExpired => ExpirationDate < DateTime.UtcNow;
        public bool IsExpiringSoon => !IsExpired && ExpirationDate < DateTime.UtcNow.AddDays(30);
        public DateTime UpdatedAt { get; set; }
    }
}
