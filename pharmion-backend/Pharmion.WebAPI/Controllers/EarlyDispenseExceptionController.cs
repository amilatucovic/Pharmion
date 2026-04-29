using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Requests;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = Roles.Pharmacist)]
    public class EarlyDispenseExceptionController : ControllerBase
    {
        private readonly IEarlyDispenseExceptionService _service;
        private readonly ICurrentUserService _currentUserService;

        public EarlyDispenseExceptionController(IEarlyDispenseExceptionService service, ICurrentUserService currentUserService)
        {
            _service = service;
            _currentUserService = currentUserService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] EarlyDispenseExceptionSearchObject search)
        {
            
            var result = await _service.GetAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var result = await _service.GetByIdAsync(id);
            if (result == null)
                return NotFound(new { message = "Exception not found." });
            return Ok(result);
        }

        [HttpPost("{id}/approve")]
        public async Task<IActionResult> Approve(int id, [FromBody] ApproveExceptionRequest request)
        {
                var pharmacistId = _currentUserService.GetUserId();
                var result = await _service.ApproveAsync(id, pharmacistId, request);
                return Ok(result);
        }

        [HttpPost("{id}/reject")]
        public async Task<IActionResult> Reject(int id, [FromBody] RejectExceptionRequest request)
        {
            
                var pharmacistId = _currentUserService.GetUserId();
                var result = await _service.RejectAsync(id, pharmacistId, request);
                return Ok(result);
           
        }
    }
}