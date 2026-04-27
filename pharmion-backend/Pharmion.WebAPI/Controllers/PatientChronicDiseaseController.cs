using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Services.Interfaces;
using System.Security.Claims;
using System.Threading.Tasks;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = "Patient")]
    public class PatientChronicDiseaseController : ControllerBase
    {
        private readonly IPatientChronicDiseaseService _service;

        public PatientChronicDiseaseController(IPatientChronicDiseaseService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<IActionResult> GetMyDiseases()
        {
            var patientId = int.Parse(
                User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            var result = await _service.GetMyDiseasesAsync(patientId);
            return Ok(result);
        }

        [HttpPost("{chronicDiseaseId}")]
        public async Task<IActionResult> AddDisease(int chronicDiseaseId)
        {
            try
            {
                var patientId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                await _service.AddDiseaseAsync(patientId, chronicDiseaseId);
                return Ok(new { message = "Disease added successfully." });
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{chronicDiseaseId}")]
        public async Task<IActionResult> RemoveDisease(int chronicDiseaseId)
        {
            try
            {
                var patientId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                await _service.RemoveDiseaseAsync(patientId, chronicDiseaseId);
                return Ok(new { message = "Disease removed successfully." });
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}