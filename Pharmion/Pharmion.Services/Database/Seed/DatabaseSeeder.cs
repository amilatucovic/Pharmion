using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAllAsync(PharmionDbContext context)
        {
            // 1. Nezavisni entiteti (bez FK)
            await new CitySeed().SeedAsync(context);
            await new ChronicDiseaseSeed().SeedAsync(context);
            await new MedicationCategorySeed().SeedAsync(context);
            await new PharmacologicalCategorySeed().SeedAsync(context);
            await new ProductSeed().SeedAsync(context);

            // 2. Entiteti koji zavise od nezavisnih (imaju FK)
            await new PharmacySeed().SeedAsync(context);
            await new PharmacistSeed().SeedAsync(context);
            await new PatientSeed().SeedAsync(context);
            await new MedicationDetailSeed().SeedAsync(context);
            await new SupplementDetailSeed().SeedAsync(context);
        }
    }
}