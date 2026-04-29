using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class RecommendationController : ControllerBase
    {
        private readonly IRecommendationService _recommendationService;
        private readonly ICurrentUserService _currentUserService;

        public RecommendationController(IRecommendationService recommendationService, ICurrentUserService currentUserService)
        {
            _recommendationService = recommendationService;
            _currentUserService = currentUserService;
        }

        [HttpGet("{patientId}")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> GetRecommendations(int patientId)
        {
            try
            {
                var userId = _currentUserService.GetUserId();
                if (patientId != userId)
                    return Forbid();

                var recommendations = await _recommendationService.GetRecommendationsAsync(patientId);
                return Ok(recommendations);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }
    }
}
