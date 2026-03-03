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
    public class PatientSeed : IEntitySeeder<Patient>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.Patients.AnyAsync())
                return;

            
            var sarajevo = await context.Cities.FirstOrDefaultAsync(c => c.Name == "Sarajevo");
            var mostar = await context.Cities.FirstOrDefaultAsync(c => c.Name == "Mostar");
            var bugojno = await context.Cities.FirstOrDefaultAsync(c => c.Name == "Bugojno");
            var tuzla = await context.Cities.FirstOrDefaultAsync(c => c.Name == "Tuzla");
            var zenica = await context.Cities.FirstOrDefaultAsync(c => c.Name == "Zenica");

            var (hash1, salt1) = GeneratePasswordHash("Patient123!");
            var (hash2, salt2) = GeneratePasswordHash("Patient123!");
            var (hash3, salt3) = GeneratePasswordHash("Patient123!");
            var (hash4, salt4) = GeneratePasswordHash("Patient123!");
            var (hash5, salt5) = GeneratePasswordHash("Patient123!");
            var (hash6, salt6) = GeneratePasswordHash("Patient123!");
            var (hash7, salt7) = GeneratePasswordHash("Patient123!");

            var patients = new[]
            {
                new Patient
                {
                    FirstName = "Adnan",
                    LastName = "Mahmutović",
                    Username = "adnan.mahmutovic",
                    Email = "adnan.mahmutovic@gmail.com",
                    PasswordHash = hash1,
                    PasswordSalt = salt1,
                    Gender = Gender.Male,
                    Role = Role.Patient,
                    IsActive = true,
                    DateOfBirth = new DateTime(1985, 3, 15),
                    JMBG = "1503985170023",
                    InsuranceNumber = "OSI-123456789",
                    Address = "Titova 45",
                    CityId = sarajevo?.Id ?? 1,
                    PhoneNumber = "+38761234567",
                    EmergencyContact = "+38761987654 (Supruga Amela)",
                    IsInsured = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Patient
                {
                    FirstName = "Merima",
                    LastName = "Softić",
                    Username = "merima.softic",
                    Email = "merima.softic@outlook.com",
                    PasswordHash = hash2,
                    PasswordSalt = salt2,
                    Gender = Gender.Female,
                    Role = Role.Patient,
                    IsActive = true,
                    DateOfBirth = new DateTime(1992, 7, 22),
                    JMBG = "2207992175034",
                    InsuranceNumber = "OSI-987654321",
                    Address = "Branilaca Sarajeva 12",
                    CityId = sarajevo?.Id ?? 1,
                    PhoneNumber = "+38762345678",
                    EmergencyContact = "+38762876543 (Majka Fatima)",
                    IsInsured = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Patient
                {
                    FirstName = "Dženan",
                    LastName = "Husić",
                    Username = "dzenan.husic",
                    Email = "dzenan.husic@yahoo.com",
                    PasswordHash = hash3,
                    PasswordSalt = salt3,
                    Gender = Gender.Male,
                    Role = Role.Patient,
                    IsActive = true,
                    DateOfBirth = new DateTime(1978, 11, 8),
                    JMBG = "0811978170045",
                    InsuranceNumber = "OSI-456789123",
                    Address = "Maršala Tita 88",
                    CityId = mostar?.Id ?? 2,
                    PhoneNumber = "+38763456789",
                    EmergencyContact = "+38763765432 (Brat Elmir)",
                    IsInsured = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Patient
                {
                    FirstName = "Aida",
                    LastName = "Begić",
                    Username = "aida.begic",
                    Email = "aida.begic@gmail.com",
                    PasswordHash = hash4,
                    PasswordSalt = salt4,
                    Gender = Gender.Female,
                    Role = Role.Patient,
                    IsActive = true,
                    DateOfBirth = new DateTime(1995, 5, 30),
                    JMBG = "3005995175056",
                    InsuranceNumber = null, 
                    Address = "307 Motorizovane brigade 92",
                    CityId = bugojno?.Id ?? 3,
                    PhoneNumber = "+38765567890",
                    EmergencyContact = "+38765098765 (Otac Senad)",
                    IsInsured = false,
                    CreatedAt = DateTime.UtcNow
                },
                new Patient
                {
                    FirstName = "Haris",
                    LastName = "Hodžić",
                    Username = "haris.hodzic",
                    Email = "haris.hodzic@hotmail.com",
                    PasswordHash = hash5,
                    PasswordSalt = salt5,
                    Gender = Gender.Male,
                    Role = Role.Patient,
                    IsActive = true,
                    DateOfBirth = new DateTime(1988, 9, 12),
                    JMBG = "1209988170067",
                    InsuranceNumber = "OSI-753951456",
                    Address = "Turalibegova 67",
                    CityId = tuzla?.Id ?? 4,
                    PhoneNumber = "+38766678901",
                    EmergencyContact = "+38766456789 (Sestra Lejla)",
                    IsInsured = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Patient
                {
                    FirstName = "Sajra",
                    LastName = "Mulić",
                    Username = "sajra.mulic",
                    Email = "sajra.mulic@gmail.com",
                    PasswordHash = hash6,
                    PasswordSalt = salt6,
                    Gender = Gender.Female,
                    Role = Role.Patient,
                    IsActive = true,
                    DateOfBirth = new DateTime(2000, 2, 14),
                    JMBG = "1402000175078",
                    InsuranceNumber = "OSI-159753852",
                    Address = "Kamberović Polje 34",
                    CityId = zenica?.Id ?? 5,
                    PhoneNumber = "+38767789012",
                    EmergencyContact = "+38767345678 (Majka Hanifa)",
                    IsInsured = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Patient
                {
                    FirstName = "Kenan",
                    LastName = "Žuljević",
                    Username = "kenan.zuljevic",
                    Email = "kenan.zuljevic@outlook.com",
                    PasswordHash = hash7,
                    PasswordSalt = salt7,
                    Gender = Gender.Male,
                    Role = Role.Patient,
                    IsActive = true,
                    DateOfBirth = new DateTime(1982, 12, 25),
                    JMBG = "2512982170089",
                    InsuranceNumber = "OSI-357159246",
                    Address = "Zmaja od Bosne 55",
                    CityId = sarajevo?.Id ?? 1,
                    PhoneNumber = "+38768890123",
                    EmergencyContact = "+38768234567 (Supruga Amra)",
                    IsInsured = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.Patients.AddRangeAsync(patients);
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