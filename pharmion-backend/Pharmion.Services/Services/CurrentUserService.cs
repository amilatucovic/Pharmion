using Microsoft.AspNetCore.Http;
using System.Security.Claims;

public class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int GetUserId()
    {
        var value = _httpContextAccessor.HttpContext?.User
            .FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(value, out var id) ? id : 0;
    }

    public string GetRole() =>
        _httpContextAccessor.HttpContext?.User
            .FindFirst(ClaimTypes.Role)?.Value ?? string.Empty;

    public bool IsAdministrator() =>
        _httpContextAccessor.HttpContext?.User
            .FindFirst("IsAdministrator")?.Value == "True";
}