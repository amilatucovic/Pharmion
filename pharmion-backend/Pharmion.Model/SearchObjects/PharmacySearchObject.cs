using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.SearchObjects
{
    public class PharmacySearchObject : BaseSearchObject
    {
        public string Name { get; set; } = string.Empty;
        public bool? IsActive { get; set; }
        public int? CityId { get; set; }
    }
}
