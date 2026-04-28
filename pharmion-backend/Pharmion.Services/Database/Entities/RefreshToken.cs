using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Pharmion.Services.Database.Entities
{
    public class RefreshToken
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [ForeignKey(nameof(User))]
        public int UserId { get; set; }
        public User? User { get; set; }

        [Required]
        [MaxLength(500)]
        public string Token { get; set; } = string.Empty;

        [Required]
        public DateTime ExpiresAt { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public bool IsRevoked { get; set; } = false;

        public DateTime? RevokedAt { get; set; }

        [MaxLength(200)]
        public string? ReplacedByToken { get; set; } 

        [MaxLength(100)]
        public string? CreatedByIp { get; set; }

        [MaxLength(100)]
        public string? RevokedByIp { get; set; }

        public bool IsExpired => DateTime.UtcNow >= ExpiresAt;
        public bool IsActive => !IsRevoked && !IsExpired;
    }
}