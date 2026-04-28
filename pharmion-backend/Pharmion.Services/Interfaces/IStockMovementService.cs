using Pharmion.Model.Requests;
using Pharmion.Model.Responses;

namespace Pharmion.Services.Interfaces
{
    public interface IStockMovementService
    {
        Task<StockMovementResponse> AddMovementAsync(StockMovementRequest request, int pharmacistId);
    }
}
