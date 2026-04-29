using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = Roles.Patient)]
    public class PatientChronicDiseaseController : ControllerBase
    {
        private readonly IPatientChronicDiseaseService _service;
        private readonly ICurrentUserService _currentUserService;

        public PatientChronicDiseaseController(IPatientChronicDiseaseService service, ICurrentUserService currentUserService)
        {
            _service = service;
            _currentUserService = currentUserService;
        }

        [HttpGet]
        public async Task<IActionResult> GetMyDiseases()
        {
            var patientId = _currentUserService.GetUserId();
            var result = await _service.GetMyDiseasesAsync(patientId);
            return Ok(result);
        }

        [HttpPost("{chronicDiseaseId}")]
        public async Task<IActionResult> AddDisease(int chronicDiseaseId)
        {
            
                var patientId = _currentUserService.GetUserId();
                await _service.AddDiseaseAsync(patientId, chronicDiseaseId);
                return Ok(new { message = "Disease added successfully." });
            
        }

        [HttpDelete("{chronicDiseaseId}")]
        public async Task<IActionResult> RemoveDisease(int chronicDiseaseId)
        {
            
                var patientId = _currentUserService.GetUserId();
                await _service.RemoveDiseaseAsync(patientId, chronicDiseaseId);
                return Ok(new { message = "Disease removed successfully." });
            
        }
    }
}