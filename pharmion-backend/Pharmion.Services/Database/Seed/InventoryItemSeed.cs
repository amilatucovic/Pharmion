using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;

namespace Pharmion.Services.Database.Seed
{
    public class InventoryItemSeed : IEntitySeeder<InventoryItem>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.InventoryItems.AnyAsync())
                return;

            var pharmacies = await context.Pharmacies.ToListAsync();
            var products = await context.Products.ToListAsync();

            if (!pharmacies.Any() || !products.Any()) return;

            var inventoryItems = new List<InventoryItem>();

            foreach (var pharmacy in pharmacies)
            {
                foreach (var product in products)
                {
                    inventoryItems.Add(new InventoryItem
                    {
                        PharmacyId = pharmacy.Id,
                        ProductId = product.Id,
                        QuantityOnHand = 150,
                        ReservedQuantity = 0,
                        ReorderLevel = 20,
                        ExpirationDate = DateTime.UtcNow.AddYears(2),
                        UpdatedAt = DateTime.UtcNow
                    });
                }
            }

            await context.InventoryItems.AddRangeAsync(inventoryItems);
            await context.SaveChangesAsync();
        }
    }
}