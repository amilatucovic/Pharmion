using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class InventoryItemController
        : BaseCRUDController<InventoryItemResponse, InventoryItemSearchObject, InventoryItemInsertRequest, InventoryItemUpdateRequest>
    {
        public InventoryItemController(IInventoryItemService service) : base(service)
        {
        }

        [HttpPost]
        [Authorize(Policies.AdminOnly)]
        public override Task<IActionResult> Create([FromBody] InventoryItemInsertRequest request)
            => base.Create(request);

        [HttpPut("{id}")]
        [Authorize(Policy = Policies.AdminOnly)]
        public override Task<IActionResult> Update(int id, [FromBody] InventoryItemUpdateRequest request)
            => base.Update(id, request);

        [HttpDelete("{id}")]
        [Authorize(Policy = Policies.AdminOnly)]
        public override Task<IActionResult> Delete(int id)
            => base.Delete(id);
    }
}