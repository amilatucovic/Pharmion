using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;

namespace Pharmion.Services.Interfaces
{
    public interface IInventoryItemService
        : ICRUDService<InventoryItemResponse, InventoryItemSearchObject, InventoryItemInsertRequest, InventoryItemUpdateRequest>
    {
        Task<List<PublicInventoryItemResponse>> GetPublicAsync(InventoryItemSearchObject search);
    }
}
