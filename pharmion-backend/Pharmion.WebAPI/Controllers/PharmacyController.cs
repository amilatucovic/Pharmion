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
    
    public class PharmacyController : BaseCRUDController<PharmacyResponse, PharmacySearchObject, PharmacyUpsertRequest, PharmacyUpsertRequest>
    {
        public PharmacyController(IPharmacyService pharmacyService) : base(pharmacyService)
        {
        }

        [HttpPost]
        [Authorize(Policy = Policies.AdminOnly)]
        public override Task<IActionResult> Create([FromBody] PharmacyUpsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = Policies.AdminOnly)]
        public override Task<IActionResult> Update(int id, [FromBody] PharmacyUpsertRequest request)
        {
            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = Policies.AdminOnly)]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}
