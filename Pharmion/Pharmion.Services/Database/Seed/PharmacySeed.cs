using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public class PharmacySeed : IEntitySeeder<Pharmacy>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.Pharmacies.AnyAsync())
                return;

            
            var sarajevo = await context.Cities.FirstOrDefaultAsync(c => c.Name == "Sarajevo");
            var mostar = await context.Cities.FirstOrDefaultAsync(c => c.Name == "Mostar");
            var bugojno = await context.Cities.FirstOrDefaultAsync(c => c.Name == "Bugojno");
            
            var pharmacies = new[]
            {
                new Pharmacy
                {
                    Name = "LUPRIV PHARM 15",
                    Address = "Grbavička 85",
                    CityId = sarajevo?.Id ?? 1,
                    IsActive = true
                },
                new Pharmacy
                {
                    Name = "LUPRIV PHARM 13",
                    Address = "Kočine b.b.",
                    CityId = mostar?.Id ?? 2,
                    IsActive = true
                },
                new Pharmacy
                {
                    Name = "LUPRIV PHARM 25",
                    Address = "Kulina bana 19",
                    CityId = bugojno?.Id ?? 3,
                    IsActive = true
                },
                new Pharmacy
                {
                    Name = "LUPRIV PHARM 10",
                    Address = "Braće Fejića 5",
                    CityId = mostar?.Id ?? 4,
                    IsActive = true
                },
                new Pharmacy
                {
                    Name = "LUPRIV PHARM 12",
                    Address = "Vrapčići bb",
                    CityId = mostar?.Id ?? 1,
                    IsActive = true
                }
            };

            await context.Pharmacies.AddRangeAsync(pharmacies);
            await context.SaveChangesAsync();
        }
    }
}