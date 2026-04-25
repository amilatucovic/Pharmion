using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;
using System.Security.Claims;

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

        public PrescriptionController(IPrescriptionService prescriptionService)
            : base(prescriptionService)
        {
            _prescriptionService = prescriptionService;
        }

        [HttpGet]
        [Authorize(Roles = "Pharmacist")]
        public override Task<PagedResult<PrescriptionResponse>> Get(
        [FromQuery] PrescriptionSearchObject? search = null)
        {
            return base.Get(search);
        }

        [HttpGet("{id}")]
        [Authorize(Roles = "Pharmacist")]
        public override Task<PrescriptionResponse?> GetById(int id)
        {
            return base.GetById(id);
        }

        [HttpPost]
        [Authorize(Roles = "Pharmacist")]
        public override async Task<IActionResult> Create([FromBody] PrescriptionUpsertRequest request)
        {
            try
            {
                var pharmacistId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _prescriptionService.CreateAsync(request, pharmacistId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Pharmacist")]
        public override Task<IActionResult> Update(int id, [FromBody] PrescriptionUpsertRequest request)
        {
            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Roles = "Pharmacist")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }

        [HttpPost("{id}/cancel")]
        [Authorize(Roles = "Pharmacist")]
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
        [Authorize(Roles = "Patient")]
        public async Task<IActionResult> GetMyPrescriptions([FromQuery] PrescriptionSearchObject search)
        {
            var patientId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
            search.PatientId = patientId; 
            var result = await _prescriptionService.GetAsync(search);
            return Ok(result);
        }
    }
}