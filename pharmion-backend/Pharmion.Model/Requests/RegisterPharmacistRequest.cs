using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Model.Requests
{
    
        public class RegisterPharmacistRequest
        {
            [Required]
            [MaxLength(100)]
            public string FirstName { get; set; } = string.Empty;

            [Required]
            [MaxLength(100)]
            public string LastName { get; set; } = string.Empty;

            [Required]
            [MaxLength(100)]
            public string Username { get; set; } = string.Empty;

            [Required]
            [EmailAddress]
            [MaxLength(100)]
            public string Email { get; set; } = string.Empty;

            [Required]
            [MinLength(8, ErrorMessage = "Password must be at least 8 characters")]
            public string Password { get; set; } = string.Empty;

            [Required]
            [Compare("Password", ErrorMessage = "Passwords do not match")]
            public string ConfirmPassword { get; set; } = string.Empty;

            [Required]
            public Gender Gender { get; set; }

            [Required]
            [MaxLength(50)]
            public string LicenseNumber { get; set; } = string.Empty;

            [Required]
            public int PharmacyId { get; set; }

            public bool IsAdministrator { get; set; } = false;
        }
    
}
