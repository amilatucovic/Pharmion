using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;

namespace Pharmion.Services.Interfaces
{
    public interface IChronicDiseaseService : ICRUDService<ChronicDiseaseResponse, ChronicDiseaseSearchObject, ChronicDiseaseUpsertRequest, ChronicDiseaseUpsertRequest>
    {

    }
}
