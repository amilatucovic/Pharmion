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
    public class ChronicDiseaseController : BaseCRUDController<ChronicDiseaseResponse, ChronicDiseaseSearchObject, ChronicDiseaseUpsertRequest, ChronicDiseaseUpsertRequest>
    {
        public ChronicDiseaseController(IChronicDiseaseService chronicDiseaseService) : base(chronicDiseaseService)
        {
        }

        [HttpPost]
        public override Task<IActionResult> Create([FromBody] ChronicDiseaseUpsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("{id}")]
        public override Task<IActionResult> Update(int id, [FromBody] ChronicDiseaseUpsertRequest request)
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
