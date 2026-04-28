using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Services.Interfaces;
using System.Security.Claims;

namespace Pharmion.WebAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        [HttpPost("create-intent")]
        [Authorize(Roles = "Patient")]
        public async Task<IActionResult> CreateIntent(
            [FromBody] CreatePaymentIntentRequest request)
        {
            try
            {
                var patientId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _paymentService
                    .CreatePaymentIntentAsync(patientId, request);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> Webhook()
        {
            var payload = await new StreamReader(HttpContext.Request.Body)
                .ReadToEndAsync();
            var stripeSignature = Request.Headers["Stripe-Signature"];

            try
            {
                await _paymentService.HandleWebhookAsync(payload, stripeSignature!);
                return Ok();
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("pay-on-pickup/{reservationId}")]
        [Authorize(Roles = "Pharmacist")]
        public async Task<IActionResult> PayOnPickup(int reservationId)
        {
            try
            {
                var pharmacistId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _paymentService
                    .ProcessPayOnPickupAsync(pharmacistId, reservationId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpPost("refund/{reservationId}")]
        [Authorize]
        public async Task<IActionResult> Refund(int reservationId)
        {
            try
            {
                var userId = int.Parse(
                    User.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "0");
                var result = await _paymentService
                    .RefundAsync(reservationId, userId);
                return Ok(result);
            }
            catch (UserException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
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