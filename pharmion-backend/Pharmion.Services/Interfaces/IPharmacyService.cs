using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;

namespace Pharmion.Services.Interfaces
{
    public interface IPharmacyService: ICRUDService<PharmacyResponse, PharmacySearchObject, PharmacyUpsertRequest, PharmacyUpsertRequest>
    {

    }
}
