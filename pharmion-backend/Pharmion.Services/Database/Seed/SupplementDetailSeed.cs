using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;

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
            var vitaminC = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Vitamin C"));
            var probiotic = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Probiotic"));
            var collagen = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Collagen"));
            var melatonin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Melatonin"));
            var calciumD = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Calcium + Vitamin D"));
            var ashwagandha = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Ashwagandha"));
            var multivitamin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Multivitamin"));
            var biotin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Biotin"));

            if (vitaminD == null || magnesium == null || bComplex == null || omega3 == null ||
                    iron == null || zinc == null || vitaminC == null || probiotic == null ||
                    collagen == null || melatonin == null || calciumD == null ||
                    ashwagandha == null || multivitamin == null || biotin == null) return; 

            var details = new[]
            {
                new SupplementDetail { ProductId = vitaminD.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "vitamin, bones, immunity, vitamin D deficiency" },
                new SupplementDetail { ProductId = magnesium.Id, TargetGender = null, MinAge = 12, MaxAge = null, Tags = "magnesium, muscles, nervous system, energy, fatigue" },
                new SupplementDetail { ProductId = bComplex.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "B vitamins, energy, nervous system, metabolism" },
                new SupplementDetail { ProductId = omega3.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "omega-3, heart health, brain, anti-inflammatory, fish oil" },
                new SupplementDetail { ProductId = iron.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "iron, anaemia, fatigue, haemoglobin, red blood cells" },
                new SupplementDetail { ProductId = zinc.Id, TargetGender = null, MinAge = 18, MaxAge = null, Tags = "zinc, immunity, wound healing, skin, cold and flu" },
                new SupplementDetail
                {
                    ProductId = vitaminC.Id,
                    TargetGender = null,
                    MinAge = 12,
                    MaxAge = null,
                    Tags = "vitamin C, immunity, antioxidant, cold, flu, skin"
                },
                new SupplementDetail
                {
                    ProductId = probiotic.Id,
                    TargetGender = null,
                    MinAge = 12,
                    MaxAge = null,
                    Tags = "probiotic, digestion, gut health, microbiome, immunity"
                },
                new SupplementDetail
                {
                    ProductId = collagen.Id,
                    TargetGender = Gender.Female,
                    MinAge = 18,
                    MaxAge = null,
                    Tags = "collagen, skin, anti-aging, joints, beauty, hair"
                },
                new SupplementDetail
                {
                    ProductId = melatonin.Id,
                    TargetGender = null,
                    MinAge = 18,
                    MaxAge = null,
                    Tags = "sleep, insomnia, melatonin, circadian rhythm, relaxation"
                },
                new SupplementDetail
                {
                    ProductId = calciumD.Id,
                    TargetGender = null,
                    MinAge = 30,
                    MaxAge = null,
                    Tags = "calcium, bones, osteoporosis, vitamin D, fractures"
                },
                new SupplementDetail
                {
                    ProductId = ashwagandha.Id,
                    TargetGender = null,
                    MinAge = 18,
                    MaxAge = null,
                    Tags = "stress, anxiety, adaptogen, mood, energy"
                },
                new SupplementDetail
                {
                    ProductId = multivitamin.Id,
                    TargetGender = null,
                    MinAge = 18,
                    MaxAge = null,
                    Tags = "multivitamin, general health, immunity, energy, wellness"
                },
                new SupplementDetail
                {
                    ProductId = biotin.Id,
                    TargetGender = Gender.Female,
                    MinAge = 18,
                    MaxAge = null,
                    Tags = "biotin, hair, nails, skin, beauty, vitamin B7"
                },
            };

            await context.SupplementDetails.AddRangeAsync(details);
            await context.SaveChangesAsync();
        }
    }
}