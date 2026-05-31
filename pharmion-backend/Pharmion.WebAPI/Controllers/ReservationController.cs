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
    public class ReservationController : BaseCRUDController<ReservationResponse, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest>
    {
        private readonly IReservationService _reservationService;
        private readonly ICurrentUserService _currentUserService;

        public ReservationController(IReservationService reservationService, ICurrentUserService currentUserService) : base(reservationService)
        {
            _reservationService = reservationService;
            _currentUserService = currentUserService;
        }


        [HttpPost]
        [Authorize(Roles = Roles.Patient)]
        public override async Task<IActionResult> Create([FromBody] ReservationInsertRequest request)
        {
            try
            {
               
                var userId = _currentUserService.GetUserId();

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
        [Authorize(Roles = Roles.Patient)]
        public override async Task<IActionResult> Update(int id, [FromBody] ReservationUpdateRequest request)
        {
            try 
            { 
                var reservation = await _reservationService.GetByIdAsync(id);
                if (reservation == null)
                    return NotFound();

                var userId = _currentUserService.GetUserId();
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
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> Submit(int id)
        {
            try
            {
                var patientId = _currentUserService.GetUserId();
                var result = await _reservationService.SubmitAsync(id, patientId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/approve")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> Approve(int id)
        {
            try
            {
                var pharmacistId = _currentUserService.GetUserId();
                var result = await _reservationService.ApproveAsync(id, pharmacistId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/reject")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> Reject(int id, [FromBody] RejectReservationRequest request)
        {
            try
            {
                var pharmacistId = _currentUserService.GetUserId();
                var result = await _reservationService.RejectAsync(id, pharmacistId, request.Reason);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/mark-ready")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> MarkReady(int id)
        {
            try
            {
                var pharmacistId = _currentUserService.GetUserId();
                var result = await _reservationService.MarkAsReadyAsync(id, pharmacistId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        
        [HttpPost("{id}/mark-picked-up")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> MarkPickedUp(int id)
        {
            try
            {
                var pharmacistId = _currentUserService.GetUserId();
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
                var reservation = await _reservationService.GetByIdAsync(id);
                var userId = _currentUserService.GetUserId();
                var role = _currentUserService.GetRole();

                if (role == Roles.Patient && reservation.PatientId != userId)
                    return Forbid();

                if (role == Roles.Pharmacist)
                {
                    var isAdmin = _currentUserService.IsAdministrator();
                    if (!isAdmin)
                    {
                        var pharmacyId = _currentUserService.GetPharmacyId();
                        if (pharmacyId == null || pharmacyId != reservation.PharmacyId)
                            return Forbid();
                    }
                }

                var actions = await _reservationService.GetAllowedActionsAsync(id);
                return Ok(new { allowedActions = actions });
            }
            catch (UserException ex)
            {
                return NotFound(new { message = ex.Message });
            }
        }


        [HttpGet("by-patient/{patientId}")]
        [Authorize(Roles = $"{Roles.Patient},{Roles.Pharmacist}")]
        public async Task<IActionResult> GetByPatient(int patientId)
        {
            try
            {
                
                var userId = _currentUserService.GetUserId();
                var userRole = _currentUserService.GetRole();

                if (userRole == Roles.Patient && patientId != userId)
                    return Forbid();

                var reservations = await _reservationService.GetReservationsByPatientAsync(patientId);
                return Ok(reservations);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }


        [HttpGet("by-pharmacy/{pharmacyId}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> GetByPharmacy(int pharmacyId)
        {
            try
            {
                var isAdmin = _currentUserService.IsAdministrator();

                if (!isAdmin)
                {
                    var pharmacyIdFromToken = _currentUserService.GetPharmacyId();
                    if (pharmacyIdFromToken == null) return Forbid();

                    if (pharmacyIdFromToken.Value != pharmacyId)
                        return Forbid();
                }

                var reservations = await _reservationService.GetReservationsByPharmacyAsync(pharmacyId);
                return Ok(reservations);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet("{id}/items")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> GetItems(int id)
        {
            try
            {
                var patientId = _currentUserService.GetUserId();
                var items = await _reservationService.GetItemsAsync(id, patientId);
                return Ok(items);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id}/items")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> AddItem(int id, [FromBody] ReservationItemInsertRequest request)
        {
            try
            {
                var patientId = _currentUserService.GetUserId();
                var result = await _reservationService.AddItemAsync(id, patientId, request);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPut("{id}/items/{itemId}")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> UpdateItem(int id, int itemId, [FromBody] ReservationItemUpdateRequest request)
        {
            try
            {
                var patientId = _currentUserService.GetUserId();
                var result = await _reservationService.UpdateItemAsync(id, itemId, patientId, request);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}/items/{itemId}")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> DeleteItem(int id, int itemId)
        {
            try
            {
                var patientId = _currentUserService.GetUserId();
                await _reservationService.DeleteItemAsync(id, itemId, patientId);
                return NoContent();
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("add-to-reservation")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> AddToReservation([FromBody] AddToReservationRequest request)
        {
            try
            {
                var patientId = _currentUserService.GetUserId();
                var result = await _reservationService.AddToReservationAsync(patientId, request);
                return Ok(result);
            }
            catch (EarlyDispenseRequiredException ex)
            {
               
                return StatusCode(409, new
                {
                    requiresEarlyDispenseReason = true,
                    message = ex.Message,
                    nextEligibleDate = ex.NextEligibleDate,
                    daysRemaining = ex.DaysRemaining
                });
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("{id}/cancel")]
        [Authorize(Roles = $"{Roles.Patient},{Roles.Pharmacist}")]
        public async Task<IActionResult> Cancel(int id, [FromBody] CancelReservationRequest request)
        {
            try
            {
                var reservation = await _reservationService.GetByIdAsync(id);
                var userId = _currentUserService.GetUserId();
                var role = _currentUserService.GetRole();

                if (role == Roles.Patient && reservation.PatientId != userId)
                    return Forbid();

                if (role == Roles.Pharmacist)
                {
                    var isAdmin = _currentUserService.IsAdministrator();
                    if (!isAdmin)  
                    {
                        var pharmacyId = _currentUserService.GetPharmacyId();
                        if (pharmacyId == null || pharmacyId != reservation.PharmacyId)
                            return Forbid();
                    }
                }

                var result = await _reservationService.CancelAsync(id, userId, request.Reason ?? "Cancelled");
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpGet]
        [Authorize]
        public override async Task<PagedResult<ReservationResponse>> Get([FromQuery] ReservationSearchObject? search = null)
        {
            search ??= new ReservationSearchObject();

            var userId = _currentUserService.GetUserId();
            var role = _currentUserService.GetRole();

            if (role == Roles.Patient)
                search.PatientId = userId;
            else if (role == Roles.Pharmacist)
            {
                var isAdmin = _currentUserService.IsAdministrator();
                if (!isAdmin)
                {
                    var pharmacyId = _currentUserService.GetPharmacyId();
                    if (pharmacyId == null)
                        return new PagedResult<ReservationResponse> { Items = new(), TotalCount = 0 };
                    search.PharmacyId = pharmacyId;
                }
                search.ExcludeDraft = true;
            }

            return await _reservationService.GetAsync(search);
        }

        [HttpGet("{id}")]
        [Authorize]
        public override async Task<ReservationResponse?> GetById(int id)
        {
            var reservation = await _reservationService.GetByIdAsync(id);
            if (reservation == null) return null;

            var userId = _currentUserService.GetUserId();
            var role = _currentUserService.GetRole();

            if (role == Roles.Patient && reservation.PatientId != userId)
                throw new ForbiddenException();

            if (role == Roles.Pharmacist)
            {
                var isAdmin = _currentUserService.IsAdministrator();
                if (!isAdmin)
                {
                    var pharmacyId = _currentUserService.GetPharmacyId();
                    if (pharmacyId == null || pharmacyId != reservation.PharmacyId)
                        throw new ForbiddenException();
                }
            }

            return reservation;
        }


    }
}