using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;
using System;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
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

            var (hash1, salt1) = GeneratePasswordHash("Pharmacist123!");
            var (hash2, salt2) = GeneratePasswordHash("Pharmacist123!");
            var (hash3, salt3) = GeneratePasswordHash("Admin123!");
            var (hash4, salt4) = GeneratePasswordHash("Pharmacist123!");
            var (hash5, salt5) = GeneratePasswordHash("Pharmacist123!");

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
                    IsAdministrator = true,
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
                    FirstName = "Lejla",
                    LastName = "Hadžić",
                    Username = "lejla.hadzic",
                    Email = "lejla.hadzic@lupriv.ba",
                    PasswordHash = hash3,
                    PasswordSalt = salt3,
                    Gender = Gender.Female,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2017-0789",
                    PharmacyId = luprivVrapcici?.Id ?? 3,
                    IsAdministrator = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Pharmacist
                {
                    FirstName = "Tarik",
                    LastName = "Imamović",
                    Username = "tarik.imamovic",
                    Email = "tarik.imamovic@lupriv.ba",
                    PasswordHash = hash4,
                    PasswordSalt = salt4,
                    Gender = Gender.Male,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2020-0234",
                    PharmacyId = luprivBugojno?.Id ?? 4,
                    IsAdministrator = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Pharmacist
                {
                    FirstName = "Selma",
                    LastName = "Bašić",
                    Username = "selma.basic",
                    Email = "selma.basic@lupriv.ba",
                    PasswordHash = hash5,
                    PasswordSalt = salt5,
                    Gender = Gender.Female,
                    Role = Role.Pharmacist,
                    IsActive = true,
                    LicenseNumber = "MAG-2021-0567",
                    PharmacyId = luprivKocine?.Id ?? 1,
                    IsAdministrator = false,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.Pharmacists.AddRangeAsync(pharmacists);
            await context.SaveChangesAsync();
        }

        private static (string hash, string salt) GeneratePasswordHash(string password)
        {
            byte[] saltBytes = new byte[16];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(saltBytes);
            }
            string salt = Convert.ToBase64String(saltBytes);

            using (var hmac = new HMACSHA512(saltBytes))
            {
                byte[] hashBytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
                string hash = Convert.ToBase64String(hashBytes);
                return (hash, salt);
            }
        }
    }
}