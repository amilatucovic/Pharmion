using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    
    public class CityController : BaseCRUDController<CityResponse, CitySearchObject, CityUpsertRequest, CityUpsertRequest>
    {
        public CityController(ICityService cityService) : base(cityService)
        {
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public override Task<IActionResult> Create([FromBody] CityUpsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override Task<IActionResult> Update(int id, [FromBody] CityUpsertRequest request)
        {
            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }
    }
}
