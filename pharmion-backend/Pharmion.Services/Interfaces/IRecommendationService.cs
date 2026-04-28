namespace Pharmion.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<RecommendationResponse>> GetRecommendationsAsync(int patientId);
    }
}