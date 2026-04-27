using Pharmion.Model.Responses;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface IPatientChronicDiseaseService
    {
        Task<List<PatientChronicDiseaseResponse>> GetMyDiseasesAsync(int patientId);
        Task AddDiseaseAsync(int patientId, int chronicDiseaseId);
        Task RemoveDiseaseAsync(int patientId, int chronicDiseaseId);
    }
}