using Pharmion.Model.Responses;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface IRecommendationService
    {
        Task<List<RecommendationResponse>> GetRecommendationsAsync(int patientId);
    }
}