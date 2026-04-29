using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Services.Interfaces;


namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _notificationService;
        private readonly ICurrentUserService _currentUserService;

        public NotificationController(INotificationService notificationService, ICurrentUserService currentUserService)
        {
            _notificationService = notificationService;
            _currentUserService = currentUserService;
        }

        [HttpGet("my")]
        public async Task<IActionResult> GetMyNotifications([FromQuery] bool? isRead = null)
        {
            var userId = _currentUserService.GetUserId();
            var result = await _notificationService.GetMyNotificationsAsync(userId, isRead);
            return Ok(result);
        }

        [HttpGet("my/unread-count")]
        public async Task<IActionResult> GetUnreadCount()
        {
            var userId = _currentUserService.GetUserId();
            var count = await _notificationService.GetUnreadCountAsync(userId);
            return Ok(new { count });
        }

        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
           
                var userId = _currentUserService.GetUserId();
                await _notificationService.MarkAsReadAsync(id, userId);
                return Ok(new { message = "Notification marked as read" });
           
        }

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead()
        {
            var userId = _currentUserService.GetUserId();
            await _notificationService.MarkAllAsReadAsync(userId);
            return Ok(new { message = "All notifications marked as read" });
        }
    }
}