using Pharmion.Model.Enums;
using System;
using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class RegisterPatientRequest
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
        public DateTime DateOfBirth { get; set; }

        [Required]
        [MaxLength(13)]
        [RegularExpression(@"^\d{13}$", ErrorMessage = "JMBG must be exactly 13 digits")]
        public string JMBG { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? InsuranceNumber { get; set; }

        [Required]
        public string Address { get; set; } = string.Empty;

        [Required]
        public int CityId { get; set; }

        [Required]
        [Phone]
        public string PhoneNumber { get; set; } = string.Empty;

        public string EmergencyContact { get; set; } = string.Empty;

        public bool IsInsured { get; set; } = true;
    }
}