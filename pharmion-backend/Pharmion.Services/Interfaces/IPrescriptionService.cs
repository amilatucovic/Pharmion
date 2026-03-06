using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;

namespace Pharmion.Services.Interfaces
{
    public interface IPrescriptionService
     : ICRUDService<PrescriptionResponse, PrescriptionSearchObject,
                    PrescriptionUpsertRequest, PrescriptionUpsertRequest>
    {
        Task<PrescriptionResponse> CreateAsync(PrescriptionUpsertRequest request, int pharmacistId);
        Task CancelAsync(int id);
    }
}