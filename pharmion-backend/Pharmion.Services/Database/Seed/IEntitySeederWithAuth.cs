using Pharmion.Services.Interfaces;

namespace Pharmion.Services.Database.Seed
{
    public interface IEntitySeederWithAuth<T> where T : class
    {
        Task SeedAsync(PharmionDbContext context, IPasswordHasher passwordHasher);
    }
}
