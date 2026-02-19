using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public interface IEntitySeeder<T> where T : class
    {
        Task SeedAsync(PharmionDbContext context);
    }
}
