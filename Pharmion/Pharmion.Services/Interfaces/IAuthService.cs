using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponse> LoginAsync(LoginRequest request, string ipAddress);
        Task<LoginResponse> RefreshTokenAsync(string refreshToken, string ipAddress);
        Task RevokeTokenAsync(string refreshToken, string ipAddress);
        Task<LoginResponse> RegisterPatientAsync(RegisterPatientRequest request, string ipAddress);
        Task<bool> ChangePasswordAsync(int userId, string oldPassword, string newPassword);
    }
}