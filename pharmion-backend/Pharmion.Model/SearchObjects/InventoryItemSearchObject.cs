using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.SearchObjects
{
    public class InventoryItemSearchObject : BaseSearchObject
    {
        public int? PharmacyId { get; set; }
        public int? ProductId { get; set; }
        public string? ProductName { get; set; }

        
        public bool? LowStock { get; set; }
        public int? CityId { get; set; }

        public bool? ExpiringSoon { get; set; }
    }
}
