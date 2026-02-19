using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public class SupplementDetailSeed : IEntitySeeder<SupplementDetail>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.SupplementDetails.AnyAsync())
                return;

            var vitaminD = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Vitamin D3"));
            var magnezij = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Magnezij"));

            var supplementDetails = new[]
            {
                // Vitamin D3 - Za sve uzraste i polove
                new SupplementDetail
                {
                    ProductId = vitaminD.Id,
                    TargetGender = null, // Za oba pola
                    MinAge = 18,
                    MaxAge = null, 
                    Tags = "vitamin, kosti, imunitet, deficit vitamina D"
                },
                // Magnezij - Za sve uzraste i polove
                new SupplementDetail
                {
                    ProductId = magnezij.Id,
                    TargetGender = null, // Za oba pola
                    MinAge = 12,
                    MaxAge = null,
                    Tags = "magnezij, mišići, nervni sistem, energija, umor"
                }
            };

            await context.SupplementDetails.AddRangeAsync(supplementDetails);
            await context.SaveChangesAsync();
        }
    }
}