public interface ICurrentUserService
{
    int GetUserId();
    string GetRole();
    bool IsAdministrator();
}