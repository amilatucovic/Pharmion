using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Requests;
using Pharmion.Services.Interfaces;


namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles=Roles.Pharmacist)]
    public class StockMovementController : ControllerBase
    {
        private readonly IStockMovementService _stockMovementService;
        private readonly ICurrentUserService _currentUserService;

        public StockMovementController(IStockMovementService stockMovementService, ICurrentUserService currentUserService)
        {
            _stockMovementService = stockMovementService;
            _currentUserService = currentUserService;
        }

        [HttpPost]
        public async Task<IActionResult> AddMovement([FromBody] StockMovementRequest request)
        {
            var pharmacistId = _currentUserService.GetUserId();
            var result = await _stockMovementService.AddMovementAsync(request, pharmacistId);
            return Ok(result);
        }
    }
}