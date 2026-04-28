using Pharmion.Model.Enums;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

namespace Pharmion.Services.Database.Entities
{
    public class Notification
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(User))]
        public int UserId { get; set; }
        public User? User { get; set; }

        public NotificationType Type { get; set; }
        public NotificationTemplate Template { get; set; }

        [MaxLength(200)]
        public string Title { get; set; } = string.Empty;

        [MaxLength(1000)]
        public string Message { get; set; } = string.Empty;

        public bool IsRead { get; set; } = false;
        public DateTime? ReadAt { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey(nameof(Reservation))]
        public int? ReservationId { get; set; }
        public Reservation? Reservation { get; set; }
    }
}
