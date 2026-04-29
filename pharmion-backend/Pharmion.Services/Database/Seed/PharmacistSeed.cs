using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;
using System;
using System.Security.Cryptography;
using System.Threading.Tasks;

namespace Pharmion.Services.Database.Seed
{
    public class PharmacistSeed : IEntitySeeder<Pharmacist>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.Pharmacists.AnyAsync())
                return;

            var luprivKocine = await context.Pharmacies.FirstOrDefaultAsync(p => p.Name == "LUPRIV PHARM 13");
            var luprivVrapcici = await context.Pharmacies.FirstOrDefaultAsync(p => p.Name == "LUPRIV PHARM 12");
            var luprivFejiceva = await context.Pharmacies.FirstOrDefaultAsync(p => p.Name == "LUPRIV PHARM 10");
            var luprivBugojno = await context.Pharmacies.FirstOrDefaultAsync(p => p.Name == "LUPRIV PHARM 25");
            var luprivGrbavicka = await context.Pharmacies.FirstOrDefaultAsync(p => p.Name == "LUPRIV PHARM 15");

            var (hash1, salt1) = CreatePasswordHash("Pharmacist123!");
            var (hash2, salt2) = CreatePasswordHash("Pharmacist123!");
            var (hash3, salt3) = CreatePasswordHash("Pharmacist123!");
            var (hash4, salt4) = CreatePasswordHash("Pharmacist123!");
            var (hashAdmin, saltAdmin) = CreatePasswordHash("Test123!");
            var (hashPharmacist, saltPharmacist) = CreatePasswordHash("Test123!");

            var pharmacists = new[]
            {
                new Pharmacist
                {
                    FirstName = "Naida",
                    LastName = "Tucović",
                    Username = "naida.tucovic",
                    Email = "naida.tucovic@lupriv.ba",
                    PasswordHash = hash1,
                    PasswordSalt = salt1,
                    Gender = Gender.Female,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2018-0123",
                    PharmacyId = luprivFejiceva?.Id ?? 1,
                    IsAdministrator = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Pharmacist
                {
                    FirstName = "Emir",
                    LastName = "Kovačević",
                    Username = "emir.kovacevic",
                    Email = "emir.kovacevic@lupriv.ba",
                    PasswordHash = hash2,
                    PasswordSalt = salt2,
                    Gender = Gender.Male,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2019-0456",
                    PharmacyId = luprivVrapcici?.Id ?? 2,
                    IsAdministrator = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Pharmacist
                {
                    FirstName = "Tarik",
                    LastName = "Imamović",
                    Username = "tarik.imamovic",
                    Email = "tarik.imamovic@lupriv.ba",
                    PasswordHash = hash3,
                    PasswordSalt = salt3,
                    Gender = Gender.Male,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2020-0234",
                    PharmacyId = luprivGrbavicka?.Id ?? 5,
                    IsAdministrator = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Pharmacist
                {
                    FirstName = "Selma",
                    LastName = "Bašić",
                    Username = "selma.basic",
                    Email = "selma.basic@lupriv.ba",
                    PasswordHash = hash4,
                    PasswordSalt = salt4,
                    Gender = Gender.Female,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2021-0567",
                    PharmacyId = luprivKocine?.Id ?? 1,
                    IsAdministrator = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Pharmacist
                {
                    FirstName = "Admin",
                    LastName = "Adminović",
                    Username = "admin",
                    Email = "admin@pharmion.ba",
                    PasswordHash = hashAdmin,
                    PasswordSalt = saltAdmin,
                    Gender = Gender.Male,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2015-0001",
                    PharmacyId = luprivKocine?.Id ?? 1,
                    IsAdministrator = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Pharmacist
                {
                    FirstName = "Amila",
                    LastName = "Tucović",
                    Username = "pharmacist",
                    Email = "amila.tucovic@lupriv.ba",
                    PasswordHash = hashPharmacist,
                    PasswordSalt = saltPharmacist,
                    Gender = Gender.Female,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2022-0099",
                    PharmacyId = luprivKocine?.Id ?? 1,
                    IsAdministrator = false,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.Pharmacists.AddRangeAsync(pharmacists);
            await context.SaveChangesAsync();
        }

        private static (string hash, string salt) CreatePasswordHash(string password)
        {
            byte[] saltBytes = new byte[16];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(saltBytes);
            string salt = Convert.ToBase64String(saltBytes);

            using var pbkdf2 = new Rfc2898DeriveBytes(password, saltBytes, 100000, HashAlgorithmName.SHA256);
            string hash = Convert.ToBase64String(pbkdf2.GetBytes(32));

            return (hash, salt);
        }
    }
}