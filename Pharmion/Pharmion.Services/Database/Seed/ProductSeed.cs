using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public class ProductSeed : IEntitySeeder<Product>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.Products.AnyAsync())
                return;

            var products = new[]
            {
            new Product
            {
                Name = "Amlodipin 5 mg",
                Type = ProductType.Medication,
                IsPrescriptionRequired = true,
                SKU = "MED-AML-5",
                Barcode = "387000000001",
                Manufacturer = "Krka",
                Unit = "tableta",
                PackageSize = 30,
                Price = 6.50m,
                SideEffects = "Vrtoglavica, glavobolja, oticanje gležnjeva.",
                InstructionsForUse = "Uzimati jednom dnevno, po preporuci ljekara.",
                Contraindications = "Teška hipotenzija, preosjetljivost na amlodipin.",
                ImageUrl = "/images/products/default-product.jpg",
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Metformin 850 mg",
                Type = ProductType.Medication,
                IsPrescriptionRequired = true,
                SKU = "MED-MET-850",
                Barcode = "387000000002",
                Manufacturer = "Sandoz",
                Unit = "tableta",
                PackageSize = 60,
                Price = 4.20m,
                SideEffects = "Mučnina, proljev, bol u stomaku.",
                InstructionsForUse = "Uzimati uz obrok, 1-2 puta dnevno prema terapiji.",
                Contraindications = "Teško oštećenje bubrega, metabolička acidoza.",
                ImageUrl = "/images/products/default-product.jpg",
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Salbutamol inhalator 100 mcg",
                Type = ProductType.Medication,
                IsPrescriptionRequired = true,
                SKU = "MED-SAL-100",
                Barcode = "387000000003",
                Manufacturer = "GlaxoSmithKline",
                Unit = "inhalacija",
                PackageSize = 200,
                Price = 12.80m,
                SideEffects = "Drhtavica, ubrzan rad srca.",
                InstructionsForUse = "1-2 inhalacije po potrebi.",
                Contraindications = "Preosjetljivost na salbutamol.",
                ImageUrl = "/images/products/default-product.jpg",
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Brufen 400 mg",
                Type = ProductType.Medication,
                IsPrescriptionRequired = false,
                SKU = "OTC-BRU-400",
                Barcode = "387000000004",
                Manufacturer = "Abbott",
                Unit = "tableta",
                PackageSize = 20,
                Price = 5.90m,
                SideEffects = "Želučane tegobe, mučnina.",
                InstructionsForUse = "1 tableta svakih 6-8 sati po potrebi.",
                Contraindications = "Čir na želucu, alergija na ibuprofen.",
                ImageUrl = "/images/products/default-product.jpg",
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Paracetamol 500 mg",
                Type = ProductType.Medication,
                IsPrescriptionRequired = false,
                SKU = "OTC-PAR-500",
                Barcode = "387000000005",
                Manufacturer = "Bosnalijek",
                Unit = "tableta",
                PackageSize = 20,
                Price = 3.50m,
                SideEffects = "Rijetko oštećenje jetre pri visokim dozama.",
                InstructionsForUse = "1-2 tablete svakih 6 sati po potrebi.",
                Contraindications = "Teško oštećenje jetre.",
                ImageUrl = "/images/products/default-product.jpg",
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Vitamin D3 2000 IU",
                Type = ProductType.Supplement,
                IsPrescriptionRequired = false,
                SKU = "SUP-VITD-2000",
                Barcode = "387000000006",
                Manufacturer = "Natural Pharma",
                Unit = "kapsula",
                PackageSize = 60,
                Price = 14.90m,
                SideEffects = "Rijetko hiperkalcemija pri visokim dozama.",
                InstructionsForUse = "1 kapsula dnevno uz obrok.",
                Contraindications = "Hiperkalcemija.",
                ImageUrl = "/images/products/default-product.jpg",
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Magnezij 400 mg",
                Type = ProductType.Supplement,
                IsPrescriptionRequired = false,
                SKU = "SUP-MAG-400",
                Barcode = "387000000007",
                Manufacturer = "Doppelherz",
                Unit = "tableta",
                PackageSize = 30,
                Price = 11.50m,
                SideEffects = "Proljev kod većih doza.",
                InstructionsForUse = "1 tableta dnevno.",
                Contraindications = "Teško oštećenje bubrega.",
                ImageUrl = "/images/products/default-product.jpg",
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Digitalni toplomjer",
                Type = ProductType.MedicalDevice,
                IsPrescriptionRequired = false,
                SKU = "DEV-TEMP-01",
                Barcode = "387000000008",
                Manufacturer = "Microlife",
                Unit = "komad",
                PackageSize = 1,
                Price = 18.00m,
                SideEffects = "Nema poznatih nuspojava.",
                InstructionsForUse = "Postaviti ispod pazuha ili oralno prema uputstvu.",
                Contraindications = "Nema.",
                ImageUrl = "/images/products/digitalni-toplomjer.jpg",
                CreatedAt = DateTime.UtcNow
            }
            };

            await context.Products.AddRangeAsync(products);
            await context.SaveChangesAsync();
        }
    }
}