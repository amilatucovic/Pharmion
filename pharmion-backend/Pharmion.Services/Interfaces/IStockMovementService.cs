using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Interfaces
{
    public interface IStockMovementService
    {
        Task<StockMovementResponse> AddMovementAsync(StockMovementRequest request, int pharmacistId);
    }
}
