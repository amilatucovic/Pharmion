using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Services.Interfaces;
using System.Security.Claims;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _recommendationService;

        public RecommendationController(IRecommendationService recommendationService)
        {
            _recommendationService = recommendationService;
        }

        [HttpGet("{patientId}")]
        [Authorize(Roles = "Patient")]
        public async Task<IActionResult> GetRecommendations(int patientId)
        {
            try
            {
                var userId = int.Parse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                if (patientId != userId)
                    return Forbid();

                var recommendations = await _recommendationService.GetRecommendationsAsync(patientId);
                return Ok(recommendations);
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
