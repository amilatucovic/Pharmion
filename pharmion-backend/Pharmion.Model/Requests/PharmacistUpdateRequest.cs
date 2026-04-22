using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class PharmacistUpdateRequest
    {
        [Required]
        [MaxLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        [MaxLength(100)]
        public string Email { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LicenseNumber { get; set; } = string.Empty;

        [Required]
        public int PharmacyId { get; set; }

        public bool IsAdministrator { get; set; } = false;

        public bool IsActive { get; set; } = true;
    }
}