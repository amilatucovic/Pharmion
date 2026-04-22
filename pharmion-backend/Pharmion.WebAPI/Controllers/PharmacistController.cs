using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;
using System.Threading.Tasks;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Policy = "AdminOnly")]
    public class PharmacistController : ControllerBase
    {
        private readonly IPharmacistService _pharmacistService;

        public PharmacistController(IPharmacistService pharmacistService)
        {
            _pharmacistService = pharmacistService;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll([FromQuery] PharmacistSearchObject search)
        {
            var result = await _pharmacistService.GetAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        [Authorize] 
        public async Task<IActionResult> GetById(int id)
        {
            var result = await _pharmacistService.GetByIdAsync(id);
            if (result == null)
                return NotFound(new { message = "Pharmacist not found." });
            return Ok(result);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] RegisterPharmacistRequest request)
        {
            try
            {
                var result = await _pharmacistService.CreateAsync(request);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] PharmacistUpdateRequest request)
        {
            try
            {
                var result = await _pharmacistService.UpdateAsync(id, request);
                if (result == null)
                    return NotFound(new { message = "Pharmacist not found." });
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id}/toggle-active")]
        public async Task<IActionResult> ToggleActive(int id)
        {
            try
            {
                var result = await _pharmacistService.ToggleActiveAsync(id);
                if (result == null)
                    return NotFound(new { message = "Pharmacist not found." });
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}