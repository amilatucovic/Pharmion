
namespace Pharmion.Services.Database.Seed
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAllAsync(PharmionDbContext context)
        {
            await new CitySeed().SeedAsync(context);
            await new ChronicDiseaseSeed().SeedAsync(context);
            await new MedicationCategorySeed().SeedAsync(context);
            await new PharmacologicalCategorySeed().SeedAsync(context);
            await new ProductSeed().SeedAsync(context);

            await new PharmacySeed().SeedAsync(context);
            await new PharmacistSeed().SeedAsync(context);
            await new PatientSeed().SeedAsync(context);
            await new MedicationDetailSeed().SeedAsync(context);
            await new SupplementDetailSeed().SeedAsync(context);
            await new InventoryItemSeed().SeedAsync(context);

            await new PrescriptionSeed().SeedAsync(context);
            await new ReservationSeed().SeedAsync(context);
            await new PaymentSeed().SeedAsync(context);
            await new EarlyDispenseExceptionSeed().SeedAsync(context);
        }
    }
}