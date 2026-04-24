using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface IEarlyDispenseExceptionService
    {
        Task<PagedResult<EarlyDispenseExceptionResponse>> GetAsync(EarlyDispenseExceptionSearchObject search);
        Task<EarlyDispenseExceptionResponse?> GetByIdAsync(int id);
        Task<EarlyDispenseExceptionResponse> ApproveAsync(int id, int pharmacistId, ApproveExceptionRequest request);
        Task<EarlyDispenseExceptionResponse> RejectAsync(int id, int pharmacistId, RejectExceptionRequest request);
    }
}