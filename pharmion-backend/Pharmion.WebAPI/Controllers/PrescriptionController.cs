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
        public override async Task<PagedResult<PrescriptionResponse>> Get([FromQuery] PrescriptionSearchObject? search = null)
        {
            search ??= new PrescriptionSearchObject();
            var isAdmin = _currentUserService.IsAdministrator();
            if (!isAdmin)
                search.CreatedByPharmacistId = _currentUserService.GetUserId();
            return await _prescriptionService.GetAsync(search);
        }

        [HttpGet("{id}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public override async Task<PrescriptionResponse?> GetById(int id)
        {
            var prescription = await _prescriptionService.GetByIdAsync(id);
            if (prescription == null) return null;

            var isAdmin = _currentUserService.IsAdministrator();
            if (!isAdmin && prescription.CreatedByPharmacistId != _currentUserService.GetUserId())
                throw new ForbiddenException();

            return prescription;
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
        public override async Task<IActionResult> Update(int id, [FromBody] PrescriptionUpsertRequest request)
        {
            var prescription = await _prescriptionService.GetByIdAsync(id);
            if (prescription == null) return NotFound();

            var isAdmin = _currentUserService.IsAdministrator();
            if (!isAdmin && prescription.CreatedByPharmacistId != _currentUserService.GetUserId())
                return Forbid();

            return await base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public override async Task<IActionResult> Delete(int id)
        {
            var prescription = await _prescriptionService.GetByIdAsync(id);
            if (prescription == null) return NotFound();

            var isAdmin = _currentUserService.IsAdministrator();
            if (!isAdmin && prescription.CreatedByPharmacistId != _currentUserService.GetUserId())
                return Forbid();

            return await base.Delete(id);
        }

        [HttpPost("{id}/cancel")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> Cancel(int id)
        {
            var prescription = await _prescriptionService.GetByIdAsync(id);
            if (prescription == null) return NotFound();

            var isAdmin = _currentUserService.IsAdministrator();
            if (!isAdmin && prescription.CreatedByPharmacistId != _currentUserService.GetUserId())
                return Forbid();

            await _prescriptionService.CancelAsync(id);
            return Ok(new { message = "Prescription cancelled successfully." });
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