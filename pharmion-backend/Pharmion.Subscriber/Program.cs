using EasyNetQ;
using Microsoft.Extensions.Logging;
using Pharmion.Model.Messages;

using var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
var logger = loggerFactory.CreateLogger("PharmionSubscriber");

var rabbitConnection = Environment.GetEnvironmentVariable("RABBITMQ_CONNECTIONSTRING")
    ?? "host=localhost;username=guest;password=guest";

var bus = RabbitHutch.CreateBus(rabbitConnection);
logger.LogInformation("Pharmion Subscriber started...");

await bus.PubSub.SubscribeAsync<ReservationSubmittedMessage>(
    "reservation_submitted",
    async msg => await ExecuteWithRetryAsync(
        () => SendEmailAsync(
            msg.PatientEmail,
            "Reservation successfully created - Pharmion",
            $"Dear {msg.PatientName},\n\n" +
            $"Your reservation no. {msg.ReservationId} at pharmacy {msg.PharmacyName} " +
            $"has been successfully created on {msg.CreatedAt:dd.MM.yyyy}.\n\n" +
            $"A pharmacist will review your reservation and notify you about the status.\n\n" +
            $"Best regards,\nPharmion Team", logger),
        logger, msg.PatientEmail),
    config => config.WithTopic("reservation.submitted"));

await bus.PubSub.SubscribeAsync<ReservationRejectedMessage>(
    "reservation_rejected",
    async msg => await ExecuteWithRetryAsync(
        () => SendEmailAsync(
            msg.PatientEmail,
           "Reservation rejected - Pharmion",
           $"Dear {msg.PatientName},\n\n" +
           $"Unfortunately, your reservation no. {msg.ReservationId} at pharmacy {msg.PharmacyName} " +
           $"has been rejected.\n" +
           $"Reason: {msg.Reason}\n\n" +
           $"For more information please contact the pharmacy.\n\n" +
           $"Best regards,\nPharmion Team", logger),
        logger, msg.PatientEmail),
    config => config.WithTopic("reservation.rejected"));

await bus.PubSub.SubscribeAsync<ReservationReadyMessage>(
    "reservation_ready",
    async msg => await ExecuteWithRetryAsync(
        () => SendEmailAsync(
            msg.PatientEmail,
           "Your reservation is ready - Pharmion",
           $"Dear {msg.PatientName},\n\n" +
           $"Your reservation no. {msg.ReservationId} at pharmacy {msg.PharmacyName} " +
           $"is ready for pickup.\n" +
           $"Please pick it up by: {msg.PickupDeadline:dd.MM.yyyy HH:mm}\n\n" +
           $"Best regards,\nPharmion Team", logger),
        logger, msg.PatientEmail),
    config => config.WithTopic("reservation.ready"));

await bus.PubSub.SubscribeAsync<ReservationApprovedMessage>(
    "reservation_approved",
    async msg => await ExecuteWithRetryAsync(
        () => SendEmailAsync(
            msg.PatientEmail,
           "Reservation approved - Pharmion",
           $"Dear {msg.PatientName},\n\n" +
           $"Your reservation no. {msg.ReservationId} at pharmacy {msg.PharmacyName} " +
           $"has been approved.\n\n" +
           $"Best regards,\nPharmion Team", logger),
        logger, msg.PatientEmail),
    config => config.WithTopic("reservation.approved"));

logger.LogInformation("Waiting for messages...");
await Task.Delay(Timeout.Infinite);
bus.Dispose();


static async Task ExecuteWithRetryAsync(Func<Task> action, ILogger logger,
    string context, int maxRetries = 4)
{
    int retryCount = 0;
    while (true)
    {
        try
        {
            await action();
            return;
        }
        catch (Exception ex)
        {
            retryCount++;
            if (retryCount >= maxRetries)
            {
                logger.LogError(ex,
                    "Max retries ({MaxRetries}) reached for {Context}. Giving up.",
                    maxRetries, context);
                return;
            }
            int delayMs = (int)Math.Pow(2, retryCount) * 1000; 
            logger.LogWarning(ex,
                "Retry {RetryCount}/{MaxRetries} for {Context}, waiting {Delay}s...",
                retryCount, maxRetries, delayMs / 1000, context);
            await Task.Delay(delayMs);
        }
    }
}


static async Task SendEmailAsync(string toEmail, string subject, string body, ILogger logger)
{
    string fromMail = Environment.GetEnvironmentVariable("SMTP_USERNAME")
        ?? "pharmion211@gmail.com";
    string appPassword = Environment.GetEnvironmentVariable("SMTP_PASSWORD")
        ?? "rfoz swcs ikiv vpxg";
    string smtpHost = Environment.GetEnvironmentVariable("SMTP_HOST")
        ?? "smtp.gmail.com";
    int smtpPort = int.Parse(
        Environment.GetEnvironmentVariable("SMTP_PORT") ?? "587");

    using var mailMessage = new System.Net.Mail.MailMessage();
    mailMessage.From = new System.Net.Mail.MailAddress(fromMail, "Pharmion");
    mailMessage.To.Add(toEmail);
    mailMessage.Subject = subject;
    mailMessage.Body = body;

    using var smtpClient = new System.Net.Mail.SmtpClient()
    {
        Host = smtpHost,
        Port = smtpPort,
        Credentials = new System.Net.NetworkCredential(fromMail, appPassword),
        EnableSsl = true
    };

    await smtpClient.SendMailAsync(mailMessage);
    logger.LogInformation("Email sent → {ToEmail} | {Subject}", toEmail, subject);
}