using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;

namespace Pharmion.Services.Database.Seed
{
    public class SupplementDetailSeed : IEntitySeeder<SupplementDetail>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.SupplementDetails.AnyAsync())
                return;

            var vitaminD = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Vitamin D3"));
            var magnesium = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Magnesium"));
            var bComplex = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("B-Complex"));
            var omega3 = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Omega 3"));
            var iron = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Iron supplement"));
            var zinc = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Zinc"));

            if (vitaminD == null || magnesium == null || bComplex == null || omega3 == null || iron == null || zinc == null) return;

            var details = new[]
            {
                new SupplementDetail { ProductId = vitaminD.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "vitamin, bones, immunity, vitamin D deficiency" },
                new SupplementDetail { ProductId = magnesium.Id, TargetGender = null, MinAge = 12, MaxAge = null, Tags = "magnesium, muscles, nervous system, energy, fatigue" },
                new SupplementDetail { ProductId = bComplex.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "B vitamins, energy, nervous system, metabolism" },
                new SupplementDetail { ProductId = omega3.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "omega-3, heart health, brain, anti-inflammatory, fish oil" },
                new SupplementDetail { ProductId = iron.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "iron, anaemia, fatigue, haemoglobin, red blood cells" },
                new SupplementDetail { ProductId = zinc.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "zinc, immunity, wound healing, skin, cold and flu" }
            };

            await context.SupplementDetails.AddRangeAsync(details);
            await context.SaveChangesAsync();
        }
    }
}