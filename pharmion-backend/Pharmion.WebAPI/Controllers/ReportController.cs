using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = Roles.Pharmacist)]
    public class ReportController : ControllerBase
    {
        private readonly IInventoryItemService _inventoryItemService;
        private readonly IReservationService _reservationService;
        private readonly ICurrentUserService _currentUserService;

        public ReportController(
            IInventoryItemService inventoryItemService,
            IReservationService reservationService,
            ICurrentUserService currentUserService)
        {
            _inventoryItemService = inventoryItemService;
            _reservationService = reservationService;
            _currentUserService = currentUserService;
        }

        [HttpGet("inventory")]
        public async Task<IActionResult> GetInventoryReport([FromQuery] InventoryItemSearchObject search)
        {
            search.RetrieveAll = false;
            search.Page = 0;
            search.PageSize = 1000;

            var isAdmin = _currentUserService.IsAdministrator();
            if (!isAdmin)
            {
                var pharmacyId = _currentUserService.GetPharmacyId();
                if (pharmacyId == null) return Forbid();
                search.PharmacyId = pharmacyId;
            }

            var result = await _inventoryItemService.GetAsync(search);
            return Ok(result);
        }

        [HttpGet("reservations")]
        public async Task<IActionResult> GetReservationsReport([FromQuery] ReservationSearchObject search)
        {
            search.RetrieveAll = false;
            search.Page = 0;
            search.PageSize = 1000;

            var isAdmin = _currentUserService.IsAdministrator();
            if (!isAdmin)
            {
                var pharmacyId = _currentUserService.GetPharmacyId();
                if (pharmacyId == null) return Forbid();
                search.PharmacyId = pharmacyId;
            }

            var result = await _reservationService.GetAsync(search);
            return Ok(result);
        }
    }
}
