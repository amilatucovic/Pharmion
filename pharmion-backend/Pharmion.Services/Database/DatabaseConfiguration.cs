using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Pharmion.Services.Database
{
    public static class DatabaseConfiguration
    {
        public static void AddDatabaseServices(this IServiceCollection services, string connectionString)
        {
            services.AddDbContext<PharmionDbContext>(options =>
                options.UseSqlServer(connectionString));
        }
    }
}
