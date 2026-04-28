using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class PharmacologicalCategoryUpsertRequest
    {
        [Required]
        [MaxLength(100, ErrorMessage = "Code must not exceed 100 characters.")]
        [RegularExpression(@"^[A-Z0-9\-]+$", ErrorMessage = "Code can only contain uppercase letters, numbers and hyphens.")]
        public string Code { get; set; } = string.Empty;

        [Required]
        [MaxLength(200, ErrorMessage = "Name must not exceed 200 characters.")]
        public string Name { get; set; } = string.Empty;

        [MaxLength(500, ErrorMessage = "Description must not exceed 500 characters.")]
        public string Description { get; set; } = string.Empty;

        public bool IsActive { get; set; } = true;
    }
}
