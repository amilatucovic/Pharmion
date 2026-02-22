using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class RefreshTokenRequest
    {
        [Required]
        public string RefreshToken { get; set; } = string.Empty;
    }
}