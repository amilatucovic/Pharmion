using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]  
    public class PatientController : BaseController<PatientResponse, PatientSearchObject>
    {
        private readonly IPatientService _patientService;
        private readonly ICurrentUserService _currentUserService;

        public PatientController(IPatientService patientService, ICurrentUserService currentUserService)
            : base(patientService)
        {
            _patientService = patientService;
            _currentUserService = currentUserService;
        }

        [HttpGet]
        [Authorize(Roles = Roles.Pharmacist)]  
        public override Task<PagedResult<PatientResponse>> Get(
            [FromQuery] PatientSearchObject? search = null)
        {
            return base.Get(search);
        }

        [HttpGet("{id}")]
        [Authorize(Roles = Roles.Pharmacist)]  
        public override Task<PatientResponse?> GetById(int id)
        {
            return base.GetById(id);
        }

        [HttpGet("me")]
        [Authorize(Roles = Roles.Patient)]  
        public async Task<IActionResult> GetMyProfile()
        {
            var patientId = _currentUserService.GetUserId();
            var patient = await _patientService.GetByIdAsync(patientId);
            if (patient == null)
                return NotFound(new { message = "Patient not found" });
            return Ok(patient);
        }
    }
}
