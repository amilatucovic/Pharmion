using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class CityUpsertRequest
    {
        [Required]
        [MaxLength(100, ErrorMessage = "Name must not exceed 100 characters.")]
        [RegularExpression(@"^[A-Za-zČčĆćŽžĐđŠš\s\-]+$", ErrorMessage = "City name can only contain letters (A-Ž, a-ž), whitespaces and hyphens (-).")]
        public string Name { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^\d{5}$", ErrorMessage = "Postal code must consist of exactly 5 digits.")]
        public string PostalCode { get; set; } = string.Empty;
    }
}
