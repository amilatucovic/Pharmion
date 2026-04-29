using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;


namespace Pharmion.Services.Database.Seed
{
    public class PaymentSeed : IEntitySeeder<Payment>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.Payments.AnyAsync())
                return;

            var pharmacist = await context.Pharmacists
                .FirstOrDefaultAsync(p => p.Username == "pharmacist");
            if (pharmacist == null) return;

            var pickedUpReservations = await context.Reservations
                .Where(r => r.ReservationState == "PickedUpReservationState")
                .ToListAsync();

            var payments = pickedUpReservations.Select(r => new Payment
            {
                ReservationId = r.Id,
                Method = PaymentMethod.PayOnPickup,
                Status = PaymentStatus.Completed,
                Amount = r.PatientPaysAmount,
                Currency = "BAM",
                ProcessedByPharmacistId = pharmacist.Id,
                CreatedAt = r.PickedUpAt ?? DateTime.UtcNow,
                PaidAt = r.PickedUpAt ?? DateTime.UtcNow
            }).ToList();

            await context.Payments.AddRangeAsync(payments);
            await context.SaveChangesAsync();
        }
    }
}