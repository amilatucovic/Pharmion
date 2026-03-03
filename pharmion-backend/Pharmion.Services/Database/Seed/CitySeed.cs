using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public class CitySeed : IEntitySeeder<City>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.Cities.AnyAsync())
                return;

            var cities = new[]
            {
                new City { Name = "Sarajevo", PostalCode = "71000" },
                new City { Name = "Mostar", PostalCode = "88000" },
                new City { Name = "Bugojno", PostalCode = "70230" },
                new City { Name = "Tuzla", PostalCode = "75000" },
                new City { Name = "Zenica", PostalCode = "72000" },
                new City { Name = "Bihać", PostalCode = "77000" },
                new City { Name = "Prijedor", PostalCode = "79000" },
                new City { Name = "Trebinje", PostalCode = "89000" },
                new City { Name = "Cazin", PostalCode = "77220" },
                new City { Name = "Goražde", PostalCode = "73000" }
            };

            await context.Cities.AddRangeAsync(cities);
            await context.SaveChangesAsync();
        }
    }
}

