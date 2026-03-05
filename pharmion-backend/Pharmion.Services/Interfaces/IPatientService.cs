using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;

namespace Pharmion.Services.Interfaces
{
    public interface IPatientService : IService<PatientResponse, PatientSearchObject>
    {
    }
}