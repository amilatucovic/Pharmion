using Pharmion.Model.Enums;
using Pharmion.Model.Responses;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface INotificationService
    {
        Task<List<NotificationResponse>> GetMyNotificationsAsync(int userId, bool? isRead = null);
        Task<int> GetUnreadCountAsync(int userId);
        Task MarkAsReadAsync(int notificationId, int userId);
        Task MarkAllAsReadAsync(int userId);
        Task CreateAsync(int userId, string title, string message,
            NotificationTemplate template, int? reservationId = null);
        void AddNotification(int userId, string title, string message,
    NotificationTemplate template, int? reservationId = null);
    }
}