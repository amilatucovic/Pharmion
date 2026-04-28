using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class BaseCRUDController<T, TSearch, TInsert, TUpdate>
            : BaseController<T, TSearch> where T : class where TSearch : BaseSearchObject, new() where TInsert : class where TUpdate : class
    {
        protected readonly ICRUDService<T, TSearch, TInsert, TUpdate> _crudService;

        public BaseCRUDController(ICRUDService<T, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _crudService = service;
        }

        [HttpPost]
        public virtual async Task<IActionResult> Create([FromBody] TInsert request)
        {
            var result = await _crudService.CreateAsync(request);
            return Ok(result);
        }

        [HttpPut("{id}")]
        public virtual async Task<IActionResult> Update(int id, [FromBody] TUpdate request)
        {
            var result = await _crudService.UpdateAsync(id, request);
            if (result == null)
                return NotFound();
            return Ok(result);
        }

        [HttpDelete("{id}")]
        public virtual async Task<IActionResult> Delete(int id)
        {
            var result = await _crudService.DeleteAsync(id);
            if (!result)
                return NotFound();
            return Ok(result);
        }
    }
}
