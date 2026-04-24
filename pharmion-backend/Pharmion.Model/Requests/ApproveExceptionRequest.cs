using System.ComponentModel.DataAnnotations;

namespace Pharmion.Model.Requests
{
    public class ApproveExceptionRequest
    {
        [MaxLength(500)]
        public string? Note { get; set; }
    }

    public class RejectExceptionRequest
    {
        [Required]
        [MaxLength(500)]
        public string Note { get; set; } = string.Empty;
    }
}