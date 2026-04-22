using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.Responses
{
    public class PharmacistResponse
    {
        public int Id { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string LicenseNumber { get; set; } = string.Empty;
        public int PharmacyId { get; set; }
        public string PharmacyName { get; set; } = string.Empty;
        public string PharmacyCity { get; set; } = string.Empty;
        public bool IsAdministrator { get; set; }
        public bool IsActive { get; set; }
        public Gender Gender { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? LastLoginAt { get; set; }
    }
}