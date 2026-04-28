using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.Responses
{
    public class NotificationResponse
    {
        public int Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        public DateTime? ReadAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public NotificationTemplate Template { get; set; }
        public string TemplateDisplay { get; set; } = string.Empty;
        public int? ReservationId { get; set; }
    }
}