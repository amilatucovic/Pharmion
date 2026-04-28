using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;

namespace Pharmion.Services.Interfaces
{
    public interface IProductService : ICRUDService<ProductResponse, ProductSearchObject, ProductInsertRequest, ProductUpdateRequest>
    {
        Task UpdateImageUrlAsync(int productId, string imageUrl);
    }
}
