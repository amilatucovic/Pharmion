using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using Stripe;


namespace Pharmion.Services.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly PharmionDbContext _context;
        private readonly IConfiguration _configuration;

        public PaymentService(PharmionDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        public async Task<PaymentResponse> CreatePaymentIntentAsync(
            int patientId, CreatePaymentIntentRequest request)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Items)
                .Include(r => r.Patient)
                .FirstOrDefaultAsync(r => r.Id == request.ReservationId)
                ?? throw new UserException("Reservation not found");

            if (reservation.PatientId != patientId)
                throw new UserException("Access denied");

            if (!reservation.ReservationState.Contains("Approved"))
                throw new UserException("Reservation must be approved before payment");

            
            var existing = await _context.Payments
                .FirstOrDefaultAsync(p => p.ReservationId == request.ReservationId
                && p.Method == request.Method
                    && (p.Status == PaymentStatus.Pending
                        || p.Status == PaymentStatus.Completed));

            if (existing != null)
            {
                if (existing.Status == PaymentStatus.Completed)
                    throw new UserException("This reservation is already paid");

                var resp = MapToResponse(existing);

                if (existing.Method == Model.Enums.PaymentMethod.Stripe &&
                    !string.IsNullOrWhiteSpace(existing.StripePaymentIntentId))
                {
                    var intentService = new PaymentIntentService();
                    var intent2 = await intentService.GetAsync(existing.StripePaymentIntentId);

                    resp.ClientSecret = intent2.ClientSecret;

                    
                    if (intent2.Status == "succeeded")
                    {
                        existing.Status = PaymentStatus.Completed;
                        existing.PaidAt = DateTime.UtcNow;
                        await _context.SaveChangesAsync();
                        resp = MapToResponse(existing);
                    }
                }

                return resp;
            }

            if (request.Method == Model.Enums.PaymentMethod.PayOnPickup)
            {
                var payOnPickupPayment = new Payment
                {
                    ReservationId = request.ReservationId,
                    Method = Model.Enums.PaymentMethod.PayOnPickup,
                    Status = PaymentStatus.Pending,
                    Amount = reservation.PatientPaysAmount,
                    Currency = "EUR",
                    CreatedAt = DateTime.UtcNow
                };
                _context.Payments.Add(payOnPickupPayment);

                var pharmacistsPop = await _context.Pharmacists
        .Where(p => p.PharmacyId == reservation.PharmacyId)
        .ToListAsync();
                var patientNamePop = $"{reservation.Patient!.FirstName} {reservation.Patient.LastName}";
                foreach (var ph in pharmacistsPop)
                {
                    _context.Notifications.Add(new Notification
                    {
                        UserId = ph.Id,
                        Title = "Patient has selected payment method",
                        Message = $"{patientNamePop} has selected Pay on Pickup for reservation RES-{reservation.Id}.",
                        Template = NotificationTemplate.PaymentSelected,
                        Type = NotificationType.InApp,
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow,
                        ReservationId = reservation.Id
                    });
                }
                await _context.SaveChangesAsync();
                return MapToResponse(payOnPickupPayment);
            }

            
            var amountInEur = Math.Round(reservation.PatientPaysAmount / 1.955m, 2);
            var amountInCents = (long)(amountInEur * 100);

            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = "eur",
                Metadata = new System.Collections.Generic.Dictionary<string, string>
                {
                    { "reservationId", reservation.Id.ToString() },
                    { "patientId", patientId.ToString() }
                },
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                }
            };

            var service = new PaymentIntentService();
            var intent = await service.CreateAsync(options);

            var payment = new Payment
            {
                ReservationId = request.ReservationId,
                Method = Model.Enums.PaymentMethod.Stripe,
                Status = PaymentStatus.Pending,
                Amount = reservation.PatientPaysAmount,
                Currency = "EUR",
                StripePaymentIntentId = intent.Id,
                CreatedAt = DateTime.UtcNow
            };

            _context.Payments.Add(payment);
            var pharmacists = await _context.Pharmacists
     .Where(p => p.PharmacyId == reservation.PharmacyId)
     .ToListAsync();

            var patientName = $"{reservation.Patient!.FirstName} {reservation.Patient.LastName}";
            var methodName = "Stripe";

            foreach (var ph in pharmacists)
            {
                _context.Notifications.Add(new Notification
                {
                    UserId = ph.Id,
                    Title = "Patient has selected payment method",
                    Message = $"{patientName} has selected {methodName} for reservation RES-{reservation.Id}.",
                    Template = NotificationTemplate.PaymentSelected,
                    Type = NotificationType.InApp,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow,
                    ReservationId = reservation.Id
                });
            }
            await _context.SaveChangesAsync();

            var response = MapToResponse(payment);
            response.ClientSecret = intent.ClientSecret;
            return response;
        }

        public async Task<PaymentResponse> HandleWebhookAsync(
            string payload, string stripeSignature)
        {
            var webhookSecret = _configuration["Stripe:WebhookSecret"];

            Event stripeEvent;
            try
            {
                stripeEvent = EventUtility.ConstructEvent(
                    payload, stripeSignature, webhookSecret);
            }
            catch (StripeException)
            {
                throw new UserException("Invalid webhook signature");
            }

            if (stripeEvent.Type == EventTypes.PaymentIntentSucceeded)
            {
                var intent = stripeEvent.Data.Object as PaymentIntent;
                if (intent == null) throw new UserException("Invalid event data");

                var payment = await _context.Payments
                    .FirstOrDefaultAsync(p => p.StripePaymentIntentId == intent.Id);

                if (payment == null) throw new UserException("Payment not found");

                
                if (payment.Status == PaymentStatus.Completed)
                    return MapToResponse(payment);

                payment.Status = PaymentStatus.Completed;
                payment.PaidAt = DateTime.UtcNow;
                


                var reservation = await _context.Reservations
                    .FirstOrDefaultAsync(r => r.Id == payment.ReservationId)
                    ?? throw new UserException("Reservation not found");

                

                await _context.SaveChangesAsync();
                return MapToResponse(payment);
            }

            if (stripeEvent.Type == EventTypes.PaymentIntentPaymentFailed)
            {
                var intent = stripeEvent.Data.Object as PaymentIntent;
                if (intent == null) throw new UserException("Invalid event data");

                var payment = await _context.Payments
                    .FirstOrDefaultAsync(p => p.StripePaymentIntentId == intent.Id);

                if (payment != null)
                {
                    payment.Status = PaymentStatus.Failed;
                    await _context.SaveChangesAsync();
                }
            }

            return new PaymentResponse();
        }

        public async Task<PaymentResponse> ProcessPayOnPickupAsync(int pharmacistId, int reservationId)
        {
            var payment = await _context.Payments
                .Include(p => p.Reservation) 
                .FirstOrDefaultAsync(p => p.ReservationId == reservationId
                    && p.Method == Model.Enums.PaymentMethod.PayOnPickup)
                ?? throw new UserException("Pay on pickup payment not found");

            if (payment.Status == PaymentStatus.Completed)
                throw new UserException("Payment already completed");

            var pharmacist = await _context.Pharmacists.FindAsync(pharmacistId);
            if (pharmacist == null || pharmacist.PharmacyId != payment.Reservation!.PharmacyId)
                throw new UserException("You can only process payments for reservations from your pharmacy");

            payment.Status = PaymentStatus.Completed;
            payment.PaidAt = DateTime.UtcNow;
            payment.ProcessedByPharmacistId = pharmacistId;

            await _context.SaveChangesAsync();
            return MapToResponse(payment);
        }

        public async Task<PaymentResponse> RefundAsync(int reservationId, int userId, string userRole, int? pharmacyId)
        {
            var payment = await _context.Payments
                .Include(p => p.Reservation)
                .FirstOrDefaultAsync(p => p.ReservationId == reservationId
                    && p.Status == PaymentStatus.Completed)
                ?? throw new UserException("No completed payment found for this reservation");

            if (userRole == "Patient" && payment.Reservation!.PatientId != userId)
                throw new ForbiddenException();

            if (userRole == "Pharmacist" && (pharmacyId == null || payment.Reservation!.PharmacyId != pharmacyId))
                throw new ForbiddenException();

            if (payment.Method == Model.Enums.PaymentMethod.PayOnPickup)
                throw new UserException("Pay on pickup payments cannot be refunded through the system");

            if (string.IsNullOrEmpty(payment.StripePaymentIntentId))
                throw new UserException("No Stripe payment intent found");

            var intentService = new PaymentIntentService();
            var intent = await intentService.GetAsync(payment.StripePaymentIntentId);

            var chargeId = intent.LatestChargeId;
            if (string.IsNullOrEmpty(chargeId))
                throw new UserException("No charge found for this payment");

            var refundOptions = new RefundCreateOptions { Charge = chargeId };
            var refundService = new RefundService();
            await refundService.CreateAsync(refundOptions);

            payment.Status = PaymentStatus.Refunded;
            payment.RefundedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
            return MapToResponse(payment);
        }

        public async Task<PaymentResponse?> GetByReservationIdAsync(int reservationId, int userId, string userRole, int? pharmacyId)
        {
            var payment = await _context.Payments
                .Include(p => p.Reservation)
                .FirstOrDefaultAsync(p => p.ReservationId == reservationId);

            if (payment == null) return null;

            if (userRole == "Patient" && payment.Reservation!.PatientId != userId)
                throw new ForbiddenException();

            if (userRole == "Pharmacist" && (pharmacyId == null || payment.Reservation!.PharmacyId != pharmacyId))
                throw new ForbiddenException();

            return MapToResponse(payment);
        }

        private static PaymentResponse MapToResponse(Payment p) => new()
        {
            Id = p.Id,
            ReservationId = p.ReservationId,
            Method = p.Method,
            MethodDisplay = p.Method == Model.Enums.PaymentMethod.Stripe
         ? "Stripe" : "Pay on Pickup",
            Status = p.Status,
            StatusDisplay = p.Status.ToString(),
            Amount = p.Amount,
            AmountInEur = Math.Round(p.Amount / 1.955m, 2),
            Currency = p.Currency,
            StripePaymentIntentId = p.StripePaymentIntentId,
            IsPaid = p.Status == PaymentStatus.Completed,
            IsRefunded = p.Status == PaymentStatus.Refunded,
            CreatedAt = p.CreatedAt,
            PaidAt = p.PaidAt,
            RefundedAt = p.RefundedAt,
            RefundReason = p.RefundReason,
            ProcessedByPharmacistId = p.ProcessedByPharmacistId
        };
    }
}