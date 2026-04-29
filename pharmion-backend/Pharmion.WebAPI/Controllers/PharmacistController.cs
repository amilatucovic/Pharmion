using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Requests;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class PharmacistController : ControllerBase
    {
        private readonly IPharmacistService _pharmacistService;
        private readonly ICurrentUserService _currentUserService;

        public PharmacistController(IPharmacistService pharmacistService, ICurrentUserService currentUserService)
        {
            _pharmacistService = pharmacistService;
            _currentUserService = currentUserService;
        }

        [HttpGet]
        [Authorize(Policy = Policies.AdminOnly)]
        public async Task<IActionResult> GetAll([FromQuery] PharmacistSearchObject search)
        {
            var result = await _pharmacistService.GetAsync(search);
            return Ok(result);
        }

        [HttpGet("{id}")]
        [Authorize(Policy = Policies.AdminOnly)]
        public async Task<IActionResult> GetById(int id)
        {
            var result = await _pharmacistService.GetByIdAsync(id);
            if (result == null)
                return NotFound(new { message = "Pharmacist not found." });
            return Ok(result);
        }

        [HttpPost]
        [Authorize(Policy = Policies.AdminOnly)]
        public async Task<IActionResult> Create([FromBody] RegisterPharmacistRequest request)
        {
            
                var result = await _pharmacistService.CreateAsync(request);
                return Ok(result);
            
        }

        [HttpPut("{id}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> Update(int id, PharmacistUpdateRequest request)
        {
            var userId = _currentUserService.GetUserId();

            var isAdmin = _currentUserService.IsAdministrator();

            if (!isAdmin && userId != id)
                return Forbid();

            
                var result = await _pharmacistService.UpdateAsync(id, request);
                if (result == null)
                    return NotFound();

                return Ok(result);
           
        }

        [HttpPost("{id}/toggle-active")]
        [Authorize(Policy = Policies.AdminOnly)]
        public async Task<IActionResult> ToggleActive(int id)
        {
           
                var result = await _pharmacistService.ToggleActiveAsync(id);
                if (result == null)
                    return NotFound(new { message = "Pharmacist not found." });
                return Ok(result);
            
        }

        [HttpGet("me")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> GetMe()
        {
            var userId = _currentUserService.GetUserId();
            var result = await _pharmacistService.GetByIdAsync(userId);
            if (result == null) return NotFound();
            return Ok(result);
        }
    }
}