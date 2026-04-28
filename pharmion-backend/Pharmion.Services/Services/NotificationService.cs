using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;

namespace Pharmion.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly PharmionDbContext _context;

        public NotificationService(PharmionDbContext context)
        {
            _context = context;
        }

        public async Task<List<NotificationResponse>> GetMyNotificationsAsync(
            int userId, bool? isRead = null)
        {
            var query = _context.Notifications
                .Where(n => n.UserId == userId)
                .AsQueryable();

            if (isRead.HasValue)
                query = query.Where(n => n.IsRead == isRead.Value);

            return await query
                .OrderByDescending(n => n.CreatedAt)
                .Select(n => new NotificationResponse
                {
                    Id = n.Id,
                    Title = n.Title,
                    Message = n.Message,
                    IsRead = n.IsRead,
                    ReadAt = n.ReadAt,
                    CreatedAt = n.CreatedAt,
                    Template = n.Template,
                    TemplateDisplay = n.Template.ToString(),
                    ReservationId = n.ReservationId
                })
                .Take(50)
                .ToListAsync();
        }

        public async Task<int> GetUnreadCountAsync(int userId)
        {
            return await _context.Notifications
                .CountAsync(n => n.UserId == userId && !n.IsRead);
        }

        public async Task MarkAsReadAsync(int notificationId, int userId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId)
                ?? throw new UserException("Notification not found");

            if (notification.IsRead) return;

            notification.IsRead = true;
            notification.ReadAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }

        public async Task MarkAllAsReadAsync(int userId)
        {
            var unread = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            foreach (var n in unread)
            {
                n.IsRead = true;
                n.ReadAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
        }

        public void AddNotification(int userId, string title, string message,
    NotificationTemplate template, int? reservationId = null)
        {
            _context.Notifications.Add(new Notification
            {
                UserId = userId,
                Title = title,
                Message = message,
                Template = template,
                Type = NotificationType.InApp,
                IsRead = false,
                CreatedAt = DateTime.UtcNow,
                ReservationId = reservationId
            });
        }

        public async Task CreateAsync(int userId, string title, string message,
            NotificationTemplate template, int? reservationId = null)
        {
            AddNotification(userId, title, message, template, reservationId);
            await _context.SaveChangesAsync();
        }
    }
}