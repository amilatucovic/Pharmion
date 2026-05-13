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
        private readonly IInventoryItemService _inventoryItemService;

        public InventoryItemController(IInventoryItemService service) : base(service)
        {
            _inventoryItemService = service;
        }

        [HttpGet]
        [Authorize(Roles = Roles.Pharmacist)]
        public override Task<PagedResult<InventoryItemResponse>> Get(
            [FromQuery] InventoryItemSearchObject? search = null)
            => base.Get(search);

        [HttpGet("{id}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public override Task<InventoryItemResponse?> GetById(int id)
            => base.GetById(id);

        [HttpGet("public")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> GetPublic([FromQuery] InventoryItemSearchObject search)
        {
            var result = await _inventoryItemService.GetPublicAsync(search);
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Policy = Policies.AdminOnly)]
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