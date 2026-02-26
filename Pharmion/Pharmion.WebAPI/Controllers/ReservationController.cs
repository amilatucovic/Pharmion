using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class ReservationController : BaseCRUDController<ReservationResponse, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest>
    {
        private readonly IReservationService _reservationService;

        public ReservationController(IReservationService reservationService) : base(reservationService)
        {
            _reservationService = reservationService;
        }


        [HttpPost]
        [Authorize(Roles = "Patient")]
        public override async Task<IActionResult> Create([FromBody] ReservationInsertRequest request)
        {
            try
            {
               
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");

                if (request.PatientId != userId)
                    return Forbid();

                return await base.Create(request);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}")]
        [Authorize(Roles = "Patient")]
        public override async Task<IActionResult> Update(int id, [FromBody] ReservationUpdateRequest request)
        {
            try 
            { 
                var reservation = await _reservationService.GetByIdAsync(id);
                if (reservation == null)
                    return NotFound();

                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                if (reservation.PatientId != userId)
                    return Forbid();

                return await base.Update(id, request);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/submit")]
        [Authorize(Roles = "Patient")]
        public async Task<IActionResult> Submit(int id)
        {
            try
            {
                var patientId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _reservationService.SubmitAsync(id, patientId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/approve")]
        [Authorize(Roles = "Pharmacist")]
        public async Task<IActionResult> Approve(int id)
        {
            try
            {
                var pharmacistId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _reservationService.ApproveAsync(id, pharmacistId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/reject")]
        [Authorize(Roles = "Pharmacist")]
        public async Task<IActionResult> Reject(int id, [FromBody] RejectReservationRequest request)
        {
            try
            {
                var pharmacistId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _reservationService.RejectAsync(id, pharmacistId, request.Reason);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/mark-ready")]
        [Authorize(Roles = "Pharmacist")]
        public async Task<IActionResult> MarkReady(int id)
        {
            try
            {
                var pharmacistId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _reservationService.MarkAsReadyAsync(id, pharmacistId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/mark-picked-up")]
        [Authorize(Roles = "Pharmacist")]
        public async Task<IActionResult> MarkPickedUp(int id)
        {
            try
            {
                var pharmacistId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _reservationService.MarkAsPickedUpAsync(id, pharmacistId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

       
       
        [HttpGet("{id}/allowed-actions")]
        [Authorize]
        public async Task<IActionResult> GetAllowedActions(int id)
        {
            try
            {
                var actions = await _reservationService.GetAllowedActionsAsync(id);
                return Ok(new { allowedActions = actions });
            }
            catch (UserException ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }

       
        [HttpGet("by-patient/{patientId}")]
        [Authorize(Roles = "Patient,Pharmacist")]
        public async Task<IActionResult> GetByPatient(int patientId)
        {
            try
            {
                // Patient može vidjeti samo svoje
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

                if (userRole == "Patient" && patientId != userId)
                    return Forbid();

                var reservations = await _reservationService.GetReservationsByPatientAsync(patientId);
                return Ok(reservations);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

       
        [HttpGet("by-pharmacy/{pharmacyId}")]
        [Authorize(Roles = "Pharmacist")]
        public async Task<IActionResult> GetByPharmacy(int pharmacyId)
        {
            try
            {
                var reservations = await _reservationService.GetReservationsByPharmacyAsync(pharmacyId);
                return Ok(reservations);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}