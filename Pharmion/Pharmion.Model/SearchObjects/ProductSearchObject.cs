using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.SearchObjects
{
    public class ProductSearchObject : BaseSearchObject
    {
        public string Name { get; set; } = string.Empty;
        public ProductType? Type { get; set; }
        public bool? IsPrescriptionRequired { get; set; }
        public bool? IsActive { get; set; }
        public string? Manufacturer { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
    }
}