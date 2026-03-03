using EasyNetQ;
using Pharmion.Model.Messages;

var bus = RabbitHutch.CreateBus("host=localhost;username=guest;password=guest");
Console.WriteLine("Pharmion Subscriber pokrenut...");

await bus.PubSub.SubscribeAsync<ReservationSubmittedMessage>(
    "reservation_submitted",
    async msg => await SendEmailAsync(
        msg.PatientEmail,
        "Rezervacija uspješno kreirana - Pharmion",
        $"Poštovani/a {msg.PatientName},\n\n" +
        $"Vaša rezervacija br. {msg.ReservationId} u apoteci {msg.PharmacyName} " +
        $"je uspješno kreirana dana {msg.CreatedAt:dd.MM.yyyy}.\n\n" +
        $"Farmaceut će pregledati Vašu rezervaciju i obavijestiti Vas o statusu.\n\n" +
        $"Srdačan pozdrav,\nTim Pharmion"),
    config => config.WithTopic("reservation.submitted"));

await bus.PubSub.SubscribeAsync<ReservationRejectedMessage>(
    "reservation_rejected",
    async msg => await SendEmailAsync(
        msg.PatientEmail,
        "Rezervacija odbijena - Pharmion",
        $"Poštovani/a {msg.PatientName},\n\n" +
        $"Nažalost, Vaša rezervacija br. {msg.ReservationId} u apoteci {msg.PharmacyName} " +
        $"je odbijena.\n" +
        $"Razlog: {msg.Reason}\n\n" +
        $"Za više informacija obratite se apoteci.\n\n" +
        $"Srdačan pozdrav,\nTim Pharmion"),
    config => config.WithTopic("reservation.rejected"));

await bus.PubSub.SubscribeAsync<ReservationReadyMessage>(
    "reservation_ready",
    async msg => await SendEmailAsync(
        msg.PatientEmail,
        "Vaša rezervacija je spremna - Pharmion",
        $"Poštovani/a {msg.PatientName},\n\n" +
        $"Vaša rezervacija br. {msg.ReservationId} u apoteci {msg.PharmacyName} " +
        $"je spremna za preuzimanje.\n" +
        $"Molimo preuzmite je do: {msg.PickupDeadline:dd.MM.yyyy HH:mm}\n\n" +
        $"Srdačan pozdrav,\nTim Pharmion"),
    config => config.WithTopic("reservation.ready"));

Console.WriteLine("Čeka poruke. Pritisnite Enter za izlaz...");
Console.ReadLine();
bus.Dispose();

static async Task SendEmailAsync(string toEmail, string subject, string body)
{
    try
    {
        string fromMail = "pharmion211@gmail.com";
        string appPassword = "rfoz swcs ikiv vpxg"; 

        var mailMessage = new System.Net.Mail.MailMessage();
        mailMessage.From = new System.Net.Mail.MailAddress(fromMail, "Pharmion");
        mailMessage.To.Add(toEmail);
        mailMessage.Subject = subject;
        mailMessage.Body = body;

        var smtpClient = new System.Net.Mail.SmtpClient()
        {
            Host = "smtp.gmail.com",
            Port = 587,
            Credentials = new System.Net.NetworkCredential(fromMail, appPassword),
            EnableSsl = true
        };

        smtpClient.Send(mailMessage); 
        Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Email poslan → {toEmail} | {subject}");
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Greška: {ex.Message}");
        Console.WriteLine($"Detalji: {ex.InnerException?.Message}");
    }
}