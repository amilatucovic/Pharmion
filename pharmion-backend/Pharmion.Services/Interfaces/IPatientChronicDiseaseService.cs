using Pharmion.Model.Responses;

namespace Pharmion.Services.Interfaces
{
    public interface IPatientChronicDiseaseService
    {
        Task<List<PatientChronicDiseaseResponse>> GetMyDiseasesAsync(int patientId);
        Task AddDiseaseAsync(int patientId, int chronicDiseaseId);
        Task RemoveDiseaseAsync(int patientId, int chronicDiseaseId);
    }
}