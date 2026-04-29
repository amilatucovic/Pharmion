using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Requests;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;
        private readonly ICurrentUserService _currentUserService;

        public PaymentController(IPaymentService paymentService, ICurrentUserService currentUserService)
        {
            _paymentService = paymentService;
            _currentUserService = currentUserService;
        }

        [HttpPost("create-intent")]
        [Authorize(Roles = Roles.Patient)]
        public async Task<IActionResult> CreateIntent(
            [FromBody] CreatePaymentIntentRequest request)
        {
            
                var patientId = _currentUserService.GetUserId();
                var result = await _paymentService
                    .CreatePaymentIntentAsync(patientId, request);
                return Ok(result);
           
        }

        [HttpPost("webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> Webhook()
        {
            var payload = await new StreamReader(HttpContext.Request.Body)
                .ReadToEndAsync();
            var stripeSignature = Request.Headers["Stripe-Signature"];

           
                await _paymentService.HandleWebhookAsync(payload, stripeSignature!);
                return Ok();
            
        }

        [HttpPost("pay-on-pickup/{reservationId}")]
        [Authorize(Roles = Roles.Pharmacist)]
        public async Task<IActionResult> PayOnPickup(int reservationId)
        {
           
                var pharmacistId = _currentUserService.GetUserId();
                var result = await _paymentService
                    .ProcessPayOnPickupAsync(pharmacistId, reservationId);
                return Ok(result);
           
        }

        [HttpPost("refund/{reservationId}")]
        [Authorize]
        public async Task<IActionResult> Refund(int reservationId)
        {
            
                var userId = _currentUserService.GetUserId();
                var result = await _paymentService
                    .RefundAsync(reservationId, userId);
                return Ok(result);
           
        }

        [HttpGet("by-reservation/{reservationId}")]
        [Authorize]
        public async Task<IActionResult> GetByReservation(int reservationId)
        {
            var result = await _paymentService
                .GetByReservationIdAsync(reservationId);
            return result == null ? NotFound() : Ok(result);
        }
    }
}