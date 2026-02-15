using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.Responses
{
    public class PharmacyResponse
    {
        public int Id { get; set; }
        public string Name { get; set; } 
        public string Address { get; set; } 
        public int CityId { get; set; }
        public string CityName { get; set; } 
        public bool IsActive { get; set; }
    }
}
