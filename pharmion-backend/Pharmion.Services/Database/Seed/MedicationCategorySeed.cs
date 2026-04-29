using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;


namespace Pharmion.Services.Database.Seed
{
    public class MedicationCategorySeed : IEntitySeeder<MedicationCategory>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.MedicationCategories.AnyAsync())
                return;

            var categories = new[]
            {
                new MedicationCategory
                {
                    Code = CategoryCode.CategoryA,
                    Name = "List A – Essential Medicines",
                    Description = "Medicines fully covered by health insurance with a flat co-payment of 1 KM.",
                    PatientPaymentPercentage = 0,
                    InsurancePaymentPercentage = 100,
                    FlatFee = 1.00m,
                    CreatedAt = DateTime.UtcNow
                },
                new MedicationCategory
                {
                    Code = CategoryCode.CategoryB,
                    Name = "List B – Standard Medicines",
                    Description = "Insurance covers 60%, patient pays 40%.",
                    PatientPaymentPercentage = 40,
                    InsurancePaymentPercentage = 60,
                    FlatFee = null,
                    CreatedAt = DateTime.UtcNow
                },
                new MedicationCategory
                {
                    Code = CategoryCode.CategoryC,
                    Name = "List C – Commercial Medicines",
                    Description = "Patient pays the full price.",
                    PatientPaymentPercentage = 100,
                    InsurancePaymentPercentage = 0,
                    FlatFee = null,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.MedicationCategories.AddRangeAsync(categories);
            await context.SaveChangesAsync();
        }
    }
}