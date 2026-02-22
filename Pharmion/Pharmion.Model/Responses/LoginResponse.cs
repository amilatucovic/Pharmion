using Pharmion.Model.Enums;
using System;

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

        public string AccessToken { get; set; }  
        public string RefreshToken { get; set; }  

        public DateTime AccessTokenExpiresAt { get; set; }
        public DateTime RefreshTokenExpiresAt { get; set; }  

        public bool? IsAdministrator { get; set; }
        public int? PharmacyId { get; set; }

        public int? CityId { get; set; }
    }
}