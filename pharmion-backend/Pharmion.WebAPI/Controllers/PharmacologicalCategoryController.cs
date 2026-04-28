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
    [Authorize(Policy = "AdminOnly")]
    public class PharmacologicalCategoryController : BaseCRUDController<PharmacologicalCategoryResponse, PharmacologicalCategorySearchObject, PharmacologicalCategoryUpsertRequest, PharmacologicalCategoryUpsertRequest>
    {
        public PharmacologicalCategoryController(IPharmacologicalCategoryService pharmacologicalCategoryService) : base(pharmacologicalCategoryService)
        {
        }

        [HttpPost]
        public override Task<IActionResult> Create([FromBody] PharmacologicalCategoryUpsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("{id}")]
        public override Task<IActionResult> Update(int id, [FromBody] PharmacologicalCategoryUpsertRequest request)
        {
            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}
