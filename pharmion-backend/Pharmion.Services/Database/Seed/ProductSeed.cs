using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;

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
                    Name = "Amlodipine 5 mg",
                    Type = ProductType.Medication,
                    Description = "Amlodipine is a calcium channel blocker used to treat high blood pressure (hypertension) and chest pain (angina). It works by relaxing blood vessels so the heart does not have to work as hard.",
                    IsPrescriptionRequired = true,
                    SKU = "MED-AML-5",
                    Barcode = "387000000001",
                    Manufacturer = "Krka",
                    Unit = "tablet",
                    PackageSize = 30,
                    Price = 6.50m,
                    SideEffects = "Dizziness, headache, ankle swelling.",
                    InstructionsForUse = "Take once daily as directed by your physician.",
                    Contraindications = "Severe hypotension, hypersensitivity to amlodipine.",
                    ImageUrl = "/images/products/amlodipine.jpeg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Metformin 850 mg",
                    Type = ProductType.Medication,
                    Description = "Metformin is an oral antidiabetic medicine used to control blood sugar levels in type 2 diabetes. It reduces glucose production in the liver and improves insulin sensitivity.",
                    IsPrescriptionRequired = true,
                    SKU = "MED-MET-850",
                    Barcode = "387000000002",
                    Manufacturer = "Sandoz",
                    Unit = "tablet",
                    PackageSize = 60,
                    Price = 4.20m,
                    SideEffects = "Nausea, diarrhoea, abdominal discomfort.",
                    InstructionsForUse = "Take with meals, 1–2 times daily as prescribed.",
                    Contraindications = "Severe renal impairment, metabolic acidosis.",
                    ImageUrl = "/images/products/default-product.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Salbutamol inhaler 100 mcg",
                    Type = ProductType.Medication,
                    Description = "Salbutamol is a short-acting bronchodilator used to relieve and prevent symptoms of asthma and other breathing conditions. It quickly opens the airways to make breathing easier.",
                    IsPrescriptionRequired = true,
                    SKU = "MED-SAL-100",
                    Barcode = "387000000003",
                    Manufacturer = "GlaxoSmithKline",
                    Unit = "inhalation",
                    PackageSize = 200,
                    Price = 12.80m,
                    SideEffects = "Tremor, increased heart rate.",
                    InstructionsForUse = "1–2 inhalations as needed.",
                    Contraindications = "Hypersensitivity to salbutamol.",
                    ImageUrl = "/images/products/salbutamol-inhaler.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Brufen 400 mg",
                    Type = ProductType.Medication,
                    Description = "Brufen (ibuprofen) is a non-steroidal anti-inflammatory drug (NSAID) used to relieve pain, reduce inflammation, and lower fever. Commonly used for headaches, dental pain, menstrual cramps, and muscle aches.",
                    IsPrescriptionRequired = false,
                    SKU = "OTC-BRU-400",
                    Barcode = "387000000004",
                    Manufacturer = "Abbott",
                    Unit = "tablet",
                    PackageSize = 20,
                    Price = 5.90m,
                    SideEffects = "Gastric discomfort, nausea.",
                    InstructionsForUse = "1 tablet every 6–8 hours as needed.",
                    Contraindications = "Gastric ulcer, allergy to ibuprofen.",
                    ImageUrl = "/images/products/brufen.png",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Paracetamol 500 mg",
                    Type = ProductType.Medication,
                    Description = "Paracetamol is a widely used analgesic and antipyretic medicine for the relief of mild to moderate pain and fever. It is suitable for adults and children and is generally well tolerated.",
                    IsPrescriptionRequired = false,
                    SKU = "OTC-PAR-500",
                    Barcode = "387000000005",
                    Manufacturer = "Bosnalijek",
                    Unit = "tablet",
                    PackageSize = 20,
                    Price = 3.50m,
                    SideEffects = "Rarely, liver damage at high doses.",
                    InstructionsForUse = "1–2 tablets every 6 hours as needed.",
                    Contraindications = "Severe hepatic impairment.",
                    ImageUrl = "/images/products/paracetamol.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Vitamin D3 2000 IU",
                    Type = ProductType.Supplement,
                    Description = "Vitamin D3 supports calcium absorption, promotes bone health, and plays a key role in immune system function. Especially recommended for people with limited sun exposure or diagnosed vitamin D deficiency.",
                    IsPrescriptionRequired = false,
                    SKU = "SUP-VITD-2000",
                    Barcode = "387000000006",
                    Manufacturer = "Pharmamed",
                    Unit = "capsule",
                    PackageSize = 60,
                    Price = 14.90m,
                    SideEffects = "Rarely, hypercalcaemia at high doses.",
                    InstructionsForUse = "1 capsule daily with a meal.",
                    Contraindications = "Hypercalcaemia.",
                    ImageUrl = "/images/products/vitamin-d3.png",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Magnesium 400 mg",
                    Type = ProductType.Supplement,
                    Description = "Magnesium is an essential mineral that supports normal muscle and nerve function, energy metabolism, and the nervous system. Commonly used to reduce fatigue and muscle cramps.",
                    IsPrescriptionRequired = false,
                    SKU = "SUP-MAG-400",
                    Barcode = "387000000007",
                    Manufacturer = "Doppelherz",
                    Unit = "tablet",
                    PackageSize = 30,
                    Price = 11.50m,
                    SideEffects = "Diarrhoea at higher doses.",
                    InstructionsForUse = "1 tablet daily.",
                    Contraindications = "Severe renal impairment.",
                    ImageUrl = "/images/products/magnesium.png",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "B-Complex",
                    Type = ProductType.Supplement,
                    Description = "B-Complex contains all eight essential B vitamins (B1, B2, B3, B5, B6, B7, B9, B12) that support energy production, nervous system health, and normal metabolic function.",
                    IsPrescriptionRequired = false,
                    SKU = "SUP-BCOM-01",
                    Barcode = "387000000009",
                    Manufacturer = "BiVits Abela Pharm",
                    Unit = "tablet",
                    PackageSize = 60,
                    Price = 23.40m,
                    SideEffects = "Generally well tolerated.",
                    InstructionsForUse = "1 tablet daily with a meal.",
                    Contraindications = "Hypersensitivity to any B vitamin.",
                    ImageUrl = "/images/products/b-complex.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Omega 3 fish oil",
                    Type = ProductType.Supplement,
                    Description = "Omega-3 fatty acids (EPA and DHA) support cardiovascular health, brain function, and help reduce inflammation. Derived from high-quality fish oil, beneficial for heart and joint health.",
                    IsPrescriptionRequired = false,
                    SKU = "SUP-OME-01",
                    Barcode = "387000000020",
                    Manufacturer = "Natural Wealth",
                    Unit = "capsule",
                    PackageSize = 100,
                    Price = 22.50m,
                    SideEffects = "Fishy aftertaste.",
                    InstructionsForUse = "2 capsules daily.",
                    Contraindications = "Fish allergy.",
                    ImageUrl = "/images/products/omega-3.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Iron supplement 20 mg",
                    Type = ProductType.Supplement,
                    Description = "Iron is an essential mineral for the production of haemoglobin and healthy red blood cells. Indicated for iron deficiency anaemia and fatigue associated with low iron levels.",
                    IsPrescriptionRequired = false,
                    SKU = "SUP-IRON-01",
                    Barcode = "387000000021",
                    Manufacturer = "Solgar",
                    Unit = "tablet",
                    PackageSize = 30,
                    Price = 15.00m,
                    SideEffects = "Constipation, dark stools.",
                    InstructionsForUse = "1 tablet daily.",
                    Contraindications = "Iron overload disorders.",
                    ImageUrl = "/images/products/default-product.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Zinc 25 mg",
                    Type = ProductType.Supplement,
                    Description = "Zinc is an essential trace element that supports immune function, wound healing, and normal DNA synthesis. Particularly beneficial during cold and flu season and for maintaining healthy skin.",
                    IsPrescriptionRequired = false,
                    SKU = "SUP-ZINC-01",
                    Barcode = "387000000022",
                    Manufacturer = "Nature's Bounty",
                    Unit = "tablet",
                    PackageSize = 60,
                    Price = 12.00m,
                    SideEffects = "Nausea if taken on empty stomach.",
                    InstructionsForUse = "1 tablet daily after meal.",
                    Contraindications = "Hypersensitivity.",
                    ImageUrl = "/images/products/default-product.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Digital thermometer",
                    Type = ProductType.MedicalDevice,
                    Description = "A fast and accurate digital thermometer for measuring body temperature orally, rectally, or under the arm. Features an easy-to-read LCD display and an audible alert when measurement is complete.",
                    IsPrescriptionRequired = false,
                    SKU = "DEV-TEMP-01",
                    Barcode = "387000000008",
                    Manufacturer = "Microlife",
                    Unit = "piece",
                    PackageSize = 1,
                    Price = 18.00m,
                    SideEffects = "No known side effects.",
                    InstructionsForUse = "Place under the armpit or orally according to the instructions.",
                    Contraindications = "None.",
                    ImageUrl = "/images/products/digitalni-toplomjer.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "AVENE Cleanance gel",
                    Type = ProductType.Cosmetic,
                    Description = "Avène Cleanance is a gentle cleansing gel for oily and acne-prone skin. It removes impurities and excess sebum without disrupting the skin's natural balance, leaving skin clean and fresh.",
                    IsPrescriptionRequired = false,
                    SKU = "COS-AVE-CL",
                    Barcode = "387000000010",
                    Manufacturer = "Pierre Fabre",
                    Unit = "ml",
                    PackageSize = 200,
                    Price = 45.80m,
                    SideEffects = "Possible mild skin irritation on first use.",
                    InstructionsForUse = "Apply to damp face, massage gently and rinse. Use morning and evening.",
                    Contraindications = "Hypersensitivity to any ingredient.",
                    ImageUrl = "/images/products/avene-gel.jpeg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Becutan baby cream",
                    Type = ProductType.BabyAndChild,
                    Description = "Becutan is a gentle, dermatologically tested baby cream that moisturises and protects delicate infant skin. Free from parabens and artificial fragrances, safe for daily use on newborns and toddlers.",
                    IsPrescriptionRequired = false,
                    SKU = "BAB-BEC-01",
                    Barcode = "387000000011",
                    Manufacturer = "Alkaloid",
                    Unit = "ml",
                    PackageSize = 100,
                    Price = 7.80m,
                    SideEffects = "Rare allergic reactions.",
                    InstructionsForUse = "Apply thin layer on clean skin.",
                    Contraindications = "Hypersensitivity to ingredients.",
                    ImageUrl = "/images/products/becutan.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Baby nasal aspirator",
                    Type = ProductType.BabyAndChild,
                    Description = "A soft and safe nasal aspirator for gentle removal of nasal mucus in infants and young children. Helps relieve nasal congestion so babies can breathe, feed, and sleep more comfortably.",
                    IsPrescriptionRequired = false,
                    SKU = "BAB-ASP-01",
                    Barcode = "387000000012",
                    Manufacturer = "Chicco",
                    Unit = "piece",
                    PackageSize = 1,
                    Price = 9.50m,
                    SideEffects = "None.",
                    InstructionsForUse = "Use gently to remove nasal mucus.",
                    Contraindications = "None.",
                    ImageUrl = "/images/products/default-product.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Elastic knee support",
                    Type = ProductType.Orthopedics,
                    Description = "An adjustable elastic knee support providing compression and stability to the knee joint. Suitable for sports activities, rehabilitation after injury, and managing mild to moderate knee pain.",
                    IsPrescriptionRequired = false,
                    SKU = "ORT-KNE-01",
                    Barcode = "387000000013",
                    Manufacturer = "Orliman",
                    Unit = "piece",
                    PackageSize = 1,
                    Price = 25.00m,
                    SideEffects = "Skin irritation if worn too tight.",
                    InstructionsForUse = "Wear during physical activity.",
                    Contraindications = "Severe circulatory disorders.",
                    ImageUrl = "/images/products/elastic-knee-support.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Oscillococcinum",
                    Type = ProductType.Homeopathy,
                    Description = "Oscillococcinum is a homeopathic preparation traditionally used to relieve flu-like symptoms such as fatigue, chills, headache, and body aches. Available without a prescription.",
                    IsPrescriptionRequired = false,
                    SKU = "HOM-OSC-01",
                    Barcode = "387000000014",
                    Manufacturer = "Boiron",
                    Unit = "dose",
                    PackageSize = 6,
                    Price = 18.90m,
                    SideEffects = "Generally well tolerated.",
                    InstructionsForUse = "Dissolve under the tongue.",
                    Contraindications = "Hypersensitivity.",
                    ImageUrl = "/images/products/oscillococcinum.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Chamomile tea",
                    Type = ProductType.HerbalAndTea,
                    Description = "Chamomile tea is a traditional herbal remedy known for its calming and anti-inflammatory properties. Commonly used to promote relaxation, relieve digestive discomfort, and support restful sleep.",
                    IsPrescriptionRequired = false,
                    SKU = "HER-CHA-01",
                    Barcode = "387000000015",
                    Manufacturer = "Fructus",
                    Unit = "bag",
                    PackageSize = 20,
                    Price = 3.20m,
                    SideEffects = "Rare allergic reactions.",
                    InstructionsForUse = "Steep in hot water for 5 minutes.",
                    Contraindications = "Allergy to chamomile.",
                    ImageUrl = "/images/products/kamilica.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Mint tea",
                    Type = ProductType.HerbalAndTea,
                    Description = "Peppermint tea is a refreshing herbal drink that supports digestive health and helps relieve bloating, gas, and stomach cramps. It also has a mild cooling and soothing effect.",
                    IsPrescriptionRequired = false,
                    SKU = "HER-MIN-01",
                    Barcode = "387000000016",
                    Manufacturer = "Teekanne",
                    Unit = "bag",
                    PackageSize = 20,
                    Price = 3.50m,
                    SideEffects = "None.",
                    InstructionsForUse = "Drink after meals.",
                    Contraindications = "Severe reflux.",
                    ImageUrl = "/images/products/mint-tea.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "COVID-19 rapid test",
                    Type = ProductType.DiagnosticTest,
                    Description = "A rapid antigen test for the detection of SARS-CoV-2 (COVID-19). Provides results in 15 minutes using a nasal swab sample. Suitable for home use without laboratory equipment.",
                    IsPrescriptionRequired = false,
                    SKU = "DIA-COV-01",
                    Barcode = "387000000017",
                    Manufacturer = "Abbott",
                    Unit = "piece",
                    PackageSize = 1,
                    Price = 6.00m,
                    SideEffects = "None.",
                    InstructionsForUse = "Follow instructions in package.",
                    Contraindications = "None.",
                    ImageUrl = "/images/products/covid-test.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Antibacterial hand gel",
                    Type = ProductType.PersonalCare,
                    Description = "An alcohol-based hand sanitiser that kills 99.9% of bacteria and viruses on contact. Quick-drying formula with added moisturisers to prevent skin dryness. Ideal when soap and water are unavailable.",
                    IsPrescriptionRequired = false,
                    SKU = "PER-GEL-01",
                    Barcode = "387000000018",
                    Manufacturer = "Dettol",
                    Unit = "ml",
                    PackageSize = 50,
                    Price = 4.00m,
                    SideEffects = "Skin dryness.",
                    InstructionsForUse = "Apply on hands and rub.",
                    Contraindications = "Avoid contact with eyes.",
                    ImageUrl = "/images/products/hand-gel.jpg",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Product
                {
                    Name = "Toothpaste Sensodyne",
                    Type = ProductType.PersonalCare,
                    Description = "Sensodyne is a clinically proven toothpaste for sensitive teeth. It builds a protective layer over sensitive areas and provides lasting relief from pain caused by cold, heat, and sweet foods.",
                    IsPrescriptionRequired = false,
                    SKU = "PER-TOO-01",
                    Barcode = "387000000019",
                    Manufacturer = "GSK",
                    Unit = "ml",
                    PackageSize = 75,
                    Price = 6.70m,
                    SideEffects = "Rare sensitivity.",
                    InstructionsForUse = "Brush twice daily.",
                    Contraindications = "Hypersensitivity.",
                    ImageUrl = "/images/products/sensodyne.png",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.Products.AddRangeAsync(products);
            await context.SaveChangesAsync();
        }
    }
}