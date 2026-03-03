using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using System;
using System.Linq;
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
                    Name = "Antibakterijski lijekovi za sistemsku upotrebu",
                    Description = "Antibiotici za liječenje bakterijskih infekcija",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "N02",
                    Name = "Analgetici",
                    Description = "Lijekovi protiv bola",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "N05",
                    Name = "Psiholeptici",
                    Description = "Sedativi i anksiolitici",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "C03",
                    Name = "Diuretici",
                    Description = "Lijekovi za povećanje izlučivanja tečnosti",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "A11",
                    Name = "Vitamini",
                    Description = "Vitaminski preparati",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "A10",
                    Name = "Antidijabetici",
                    Description = "Lijekovi koji se koriste za regulaciju nivoa glukoze u krvi kod pacijenata sa dijabetesom.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "CCB",
                    Name = "Blokatori kalcijumskih kanala",
                    Description = "Lijekovi koji blokiraju ulazak kalcijuma u ćelije srčanog mišića i krvnih sudova, koriste se u terapiji hipertenzije i angine pektoris.",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "R03",
                    Name = "Lijekovi za opstruktivne bolesti disajnih puteva",
                    Description = "Bronhodilatatori i lijekovi za astmu",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new PharmacologicalCategory
                {
                    Code = "M01",
                    Name = "Antiinflamatorni i antireumatski lijekovi",
                    Description = "NSAIL i drugi protuupalni lijekovi",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.PharmacologicalCategories.AddRangeAsync(categories);
            await context.SaveChangesAsync();
        }
    }
}