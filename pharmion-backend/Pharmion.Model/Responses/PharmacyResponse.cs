using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.Responses
{
    public class PharmacyResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public int CityId { get; set; }
        public string CityName { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public string? WorkingHours { get; set; }
    }
}
