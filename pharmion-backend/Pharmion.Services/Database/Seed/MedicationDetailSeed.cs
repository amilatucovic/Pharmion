using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public class MedicationDetailSeed : IEntitySeeder<MedicationDetail>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.MedicationDetails.AnyAsync())
                return;

            var categoryA = await context.MedicationCategories
                .FirstOrDefaultAsync(mc => mc.Code == CategoryCode.CategoryA);
            var categoryB = await context.MedicationCategories
                .FirstOrDefaultAsync(mc => mc.Code == CategoryCode.CategoryB);
            var categoryC = await context.MedicationCategories
                .FirstOrDefaultAsync(mc => mc.Code == CategoryCode.CategoryC);

            var analgetici = await context.PharmacologicalCategories
                .FirstOrDefaultAsync(pc => pc.Code == "N02");
            var antiinflamatorni = await context.PharmacologicalCategories
                .FirstOrDefaultAsync(pc => pc.Code == "M01");
            var bronhodilatatori = await context.PharmacologicalCategories
                .FirstOrDefaultAsync(pc => pc.Code == "R03");
            var blokatoriKalcijumskihKanala = await context.PharmacologicalCategories
                .FirstOrDefaultAsync(pc => pc.Code == "CCB");
            var antidijabetici = await context.PharmacologicalCategories
                .FirstOrDefaultAsync(pc => pc.Code == "A10");

            var amlodipin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Amlodipin"));
            var metformin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Metformin"));
            var salbutamol = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Salbutamol"));
            var brufen = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Brufen"));
            var paracetamol = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Paracetamol"));

            var medicationDetails = new[]
            {
                // Amlodipin - Lista B (recept)
                new MedicationDetail
                {
                    ProductId = amlodipin.Id,
                    ATCCode = "C08CA01",
                    MedicationCategoryId = categoryB?.Id ?? 2,
                    PharmacologicalCategoryId = blokatoriKalcijumskihKanala?.Id, 
                    RequiresColdChain = false,
                    CreatedAt = DateTime.UtcNow
                },
                // Metformin - Lista A (recept)
                new MedicationDetail
                {
                    ProductId = metformin.Id,
                    ATCCode = "A10BA02",
                    MedicationCategoryId = categoryA?.Id ?? 1,
                    PharmacologicalCategoryId = antidijabetici?.Id, 
                    RequiresColdChain = false,
                    CreatedAt = DateTime.UtcNow
                },
                new MedicationDetail
                {
                    ProductId = salbutamol.Id,
                    ATCCode = "R03AC02",
                    MedicationCategoryId = categoryB?.Id ?? 2,
                    PharmacologicalCategoryId = bronhodilatatori?.Id,
                    RequiresColdChain = false,
                    CreatedAt = DateTime.UtcNow
                },
                new MedicationDetail
                {
                    ProductId = brufen.Id,
                    ATCCode = "M01AE01",
                    MedicationCategoryId = categoryC?.Id ?? 3,
                    PharmacologicalCategoryId = antiinflamatorni?.Id,
                    RequiresColdChain = false,
                    CreatedAt = DateTime.UtcNow
                },
                new MedicationDetail
                {
                    ProductId = paracetamol.Id,
                    ATCCode = "N02BE01",
                    MedicationCategoryId = categoryA?.Id ?? 1,
                    PharmacologicalCategoryId = analgetici?.Id,
                    RequiresColdChain = false,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.MedicationDetails.AddRangeAsync(medicationDetails);
            await context.SaveChangesAsync();
        }
    }
}