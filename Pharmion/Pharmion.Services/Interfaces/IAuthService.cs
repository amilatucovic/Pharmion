using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface IAuthService
    {
        Task<LoginResponse> LoginAsync(LoginRequest request);
        Task<LoginResponse> RegisterPatientAsync(RegisterPatientRequest request);
        Task<bool> ChangePasswordAsync(int userId, string oldPassword, string newPassword);
    }
}