using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class ChronicDiseaseUpsertRequest
    {
        [Required]
        [MaxLength(50, ErrorMessage = "Code must not exceed 50 characters.")]
        [RegularExpression(@"^[A-Z0-9\-\.]+$", ErrorMessage = "Code can only contain uppercase letters, numbers, hyphens and dots.")]
        public string Code { get; set; } = string.Empty;

        [Required]
        [MaxLength(150, ErrorMessage = "Name must not exceed 150 characters.")]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500, ErrorMessage = "Description must not exceed 500 characters.")]
        public string Description { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;
    }
}
