using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;
using System.Security.Claims;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = "Pharmacist")]
    public class EarlyDispenseExceptionController : ControllerBase
    {
        private readonly IEarlyDispenseExceptionService _service;

        public EarlyDispenseExceptionController(IEarlyDispenseExceptionService service)
        {
            _service = service;
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
            try
            {
                var pharmacistId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _service.ApproveAsync(id, pharmacistId, request);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id}/reject")]
        public async Task<IActionResult> Reject(int id, [FromBody] RejectExceptionRequest request)
        {
            try
            {
                var pharmacistId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _service.RejectAsync(id, pharmacistId, request);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}