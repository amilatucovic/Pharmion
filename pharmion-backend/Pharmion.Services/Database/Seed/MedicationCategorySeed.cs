using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;
using System;
using System.Linq;
using System.Threading.Tasks;

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
                    Name = "Lista A - Esencijalni lijekovi",
                    Description = "Lijekovi koje u potpunosti plaća zdravstveno osiguranje uz participaciju od 1 KM",
                    PatientPaymentPercentage = 0,
                    InsurancePaymentPercentage = 100,
                    FlatFee = 1.00m,
                    CreatedAt = DateTime.UtcNow
                },
                new MedicationCategory
                {
                    Code = CategoryCode.CategoryB,
                    Name = "Lista B - Standardni lijekovi",
                    Description = "Lijekovi koje osiguranje plaća 60%, pacijent 40%",
                    PatientPaymentPercentage = 40,
                    InsurancePaymentPercentage = 60,
                    FlatFee = null,
                    CreatedAt = DateTime.UtcNow
                },
                new MedicationCategory
                {
                    Code = CategoryCode.CategoryC,
                    Name = "Lista C - Komercijalni lijekovi",
                    Description = "Lijekovi koje pacijent u potpunosti plaća",
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