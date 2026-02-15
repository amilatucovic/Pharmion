using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.SearchObjects
{
    public class PharmacologicalCategorySearchObject : BaseSearchObject
    {
        public string Code { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public bool? IsActive { get; set; }
    }
}
