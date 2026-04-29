namespace Pharmion.Services.Database.Seed
{
    public interface IEntitySeeder<T> where T : class
    {
        Task SeedAsync(PharmionDbContext context);
    }
}
