using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Services.Interfaces;
using System.Security.Claims;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly IAuthService _authService;

        public AuthController(IAuthService authService)
        {
            _authService = authService;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            try
            {
                var ipAddress = GetIpAddress();
                var response = await _authService.LoginAsync(request, ipAddress);
                return Ok(response);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("refresh-token")]
        [AllowAnonymous]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest request)
        {
            try
            {
                var ipAddress = GetIpAddress();
                var response = await _authService.RefreshTokenAsync(request.RefreshToken, ipAddress);
                return Ok(response);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("revoke-token")]
        [Authorize]
        public async Task<IActionResult> RevokeToken([FromBody] RefreshTokenRequest request)
        {
            try
            {
                var ipAddress = GetIpAddress();
                await _authService.RevokeTokenAsync(request.RefreshToken, ipAddress);
                return Ok(new { message = "Token revoked successfully" });
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] RegisterPatientRequest request)
        {
            try
            {
                var ipAddress = GetIpAddress();
                var response = await _authService.RegisterPatientAsync(request, ipAddress);
                return Ok(response);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                await _authService.ChangePasswordAsync(userId, request.OldPassword, request.NewPassword);
                return Ok(new { message = "Password changed successfully" });
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("me")]
        [Authorize]
        public IActionResult GetCurrentUser()
        {
            return Ok(new
            {
                userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value,
                username = User.FindFirst(ClaimTypes.Name)?.Value,
                email = User.FindFirst(ClaimTypes.Email)?.Value,
                role = User.FindFirst(ClaimTypes.Role)?.Value
            });
        }

        private string GetIpAddress()
        {
            if (Request.Headers.ContainsKey("X-Forwarded-For"))
                return Request.Headers["X-Forwarded-For"].ToString();

            return HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
        }
    }
}