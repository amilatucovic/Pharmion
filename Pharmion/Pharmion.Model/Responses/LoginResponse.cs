using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.Responses
{
    public class LoginResponse
    {
        public int UserId { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public Role Role { get; set; }
        public string Token { get; set; }
        public DateTime ExpiresAt { get; set; }

        public bool? IsAdministrator { get; set; }
        public int? PharmacyId { get; set; }

        public int? CityId { get; set; }
    }
}
