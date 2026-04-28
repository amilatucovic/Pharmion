using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Requests;
using Pharmion.Services.Interfaces;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles ="Pharmacist")]
    public class StockMovementController : ControllerBase
    {
        private readonly IStockMovementService _stockMovementService;

        public StockMovementController(IStockMovementService stockMovementService)
        {
            _stockMovementService = stockMovementService;
        }

        [HttpPost]
        public async Task<IActionResult> AddMovement([FromBody] StockMovementRequest request)
        {
            var userIdClaim = User.FindFirst(JwtRegisteredClaimNames.Sub)
                           ?? User.FindFirst(ClaimTypes.NameIdentifier);

            if (userIdClaim == null || !int.TryParse(userIdClaim.Value, out var pharmacistId))
                return Unauthorized();

            var result = await _stockMovementService.AddMovementAsync(request, pharmacistId);
            return Ok(result);
        }
    }
}