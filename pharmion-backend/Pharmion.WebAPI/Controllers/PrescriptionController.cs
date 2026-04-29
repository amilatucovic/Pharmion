using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class PrescriptionController
        : BaseCRUDController<PrescriptionResponse, PrescriptionSearchObject,
                             PrescriptionUpsertRequest, PrescriptionUpsertRequest>
    {
        private readonly IPrescriptionService _prescriptionService;
        private readonly ICurrentUserService _currentUserService;

        public PrescriptionController(IPrescriptionService prescriptionService, ICurrentUserService currentUserService)
            : base(prescriptionService)
        {
            _prescriptionService = prescriptionService;
            _currentUserService = currentUserService;
        }

        [HttpGet]
        [Authorize(Roles = Roles.Pharmacist)]
        public override Task<PagedResult<PrescriptionResponse>> Get(
        [FromQuery] PrescriptionSearchObject? search = null)
        {
            return base.Get(search);
        }

        [HttpGet("{id}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public override Task<PrescriptionResponse?> GetById(int id)
        {
            return base.GetById(id);
        }

        [HttpPost]
        [Authorize(Roles = Roles.Pharmacist)]
        public override async Task<IActionResult> Create([FromBody] PrescriptionUpsertRequest request)
        {
            
                var pharmacistId = _currentUserService.GetUserId();
                var result = await _prescriptionService.CreateAsync(request, pharmacistId);
                return Ok(result);
            
        }

        [HttpPut("{id}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public override Task<IActionResult> Update(int id, [FromBody] PrescriptionUpsertRequest request)
        {
            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }

        [HttpPost("{id}/cancel")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> Cancel(int id)
        {
            try
            {
                await _prescriptionService.CancelAsync(id);
                return Ok(new { message = "Prescription cancelled successfully." });
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("my")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> GetMyPrescriptions([FromQuery] PrescriptionSearchObject search)
        {
            var patientId = _currentUserService.GetUserId();
            search.PatientId = patientId; 
            var result = await _prescriptionService.GetAsync(search);
            return Ok(result);
        }
    }
}