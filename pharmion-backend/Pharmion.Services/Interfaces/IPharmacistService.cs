using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;

namespace Pharmion.Services.Interfaces
{
    public interface IPharmacistService
    {
        Task<PagedResult<PharmacistResponse>> GetAsync(PharmacistSearchObject search);
        Task<PharmacistResponse?> GetByIdAsync(int id);
        Task<PharmacistResponse> CreateAsync(RegisterPharmacistRequest request);
        Task<PharmacistResponse?> UpdateAsync(int id, PharmacistUpdateRequest request);
        Task<PharmacistResponse?> ToggleActiveAsync(int id);
    }
}