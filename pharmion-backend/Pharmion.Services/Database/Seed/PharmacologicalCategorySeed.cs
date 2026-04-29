using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using System;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public class PharmacologicalCategorySeed : IEntitySeeder<PharmacologicalCategory>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.PharmacologicalCategories.AnyAsync())
                return;

            var categories = new[]
            {
                new PharmacologicalCategory
                {
                    Code = "J01",
                    Name = "Antibacterials for systemic use",
                    Description = "Antibiotics for the treatment of bacterial infections.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "N02",
                    Name = "Analgesics",
                    Description = "Pain-relief medicines.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "N05",
                    Name = "Psycholeptics",
                    Description = "Sedatives and anxiolytics.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "C03",
                    Name = "Diuretics",
                    Description = "Medicines that increase fluid excretion.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "A11",
                    Name = "Vitamins",
                    Description = "Vitamin preparations.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "A10",
                    Name = "Antidiabetics",
                    Description = "Medicines used to regulate blood glucose levels in patients with diabetes.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "C08",
                    Name = "Calcium channel blockers",
                    Description = "Medicines that block calcium entry into cardiac and vascular smooth muscle cells, used in hypertension and angina pectoris.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "R03",
                    Name = "Medicines for obstructive airway diseases",
                    Description = "Bronchodilators and medicines for asthma.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "M01",
                    Name = "Anti-inflammatory and antirheumatic medicines",
                    Description = "NSAIDs and other anti-inflammatory medicines.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "C02",
                    Name = "Antihypertensives",
                    Description = "Medicines used to treat high blood pressure (hypertension).",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "C07",
                    Name = "Beta blocking agents",
                    Description = "Medicines that reduce heart rate and blood pressure, used in hypertension and heart diseases.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "C09",
                    Name = "Agents acting on the renin-angiotensin system",
                    Description = "ACE inhibitors and ARBs used for hypertension and heart failure.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
            };

            await context.PharmacologicalCategories.AddRangeAsync(categories);
            await context.SaveChangesAsync();
        }
    }
}