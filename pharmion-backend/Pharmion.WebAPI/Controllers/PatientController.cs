using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;
using Pharmion.Services.Services;
using System.Security.Claims;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class PatientController : BaseController<PatientResponse, PatientSearchObject>
    {
        private readonly IPatientService _patientService;

        public PatientController(IPatientService patientService) : base(patientService)
        {
            _patientService = patientService;
        }

        [HttpGet("me")]
        [Authorize(Roles = "Patient")]
        public async Task<IActionResult> GetMyProfile()
        {
            try
            {
                var patientId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var patient = await _patientService.GetByIdAsync(patientId);
                if (patient == null)
                    return NotFound(new { message = "Patient not found" });
                return Ok(patient);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}