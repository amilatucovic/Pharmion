namespace Pharmion.Model.Responses
{
    public class PublicInventoryItemResponse
    {
        public int PharmacyId { get; set; }
        public string PharmacyName { get; set; } = string.Empty;
        public int ProductId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string? ProductImageUrl { get; set; }
        public bool IsAvailable { get; set; }
        public int AvailableQuantity { get; set; }
    }
}
