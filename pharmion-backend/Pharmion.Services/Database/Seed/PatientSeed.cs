using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;
using System.Security.Cryptography;

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

            var (hash1, salt1) = CreatePasswordHash("Patient123!");
            var (hash2, salt2) = CreatePasswordHash("Patient123!");
            var (hash3, salt3) = CreatePasswordHash("Patient123!");
            var (hash4, salt4) = CreatePasswordHash("Patient123!");
            var (hash5, salt5) = CreatePasswordHash("Patient123!");
            var (hash6, salt6) = CreatePasswordHash("Patient123!");
            var (hash7, salt7) = CreatePasswordHash("Patient123!");
            var (hashTest, saltTest) = CreatePasswordHash("Test123!");

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
                    EmergencyContact = "+38761987654 (Wife Amela)",
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
                    EmergencyContact = "+38762876543 (Mother Fatima)",
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
                    EmergencyContact = "+38763765432 (Brother Elmir)",
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
                    EmergencyContact = "+38765098765 (Father Senad)",
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
                    EmergencyContact = "+38766456789 (Sister Lejla)",
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
                    EmergencyContact = "+38767345678 (Mother Hanifa)",
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
                    EmergencyContact = "+38768234567 (Wife Amra)",
                    IsInsured = true,
                    CreatedAt = DateTime.UtcNow
                },
                new Patient
                {
                    FirstName = "Amila",
                    LastName = "Amilić",
                    Username = "patient",
                    Email = "tucovicamila@gmail.com",
                    PasswordHash = hashTest,
                    PasswordSalt = saltTest,
                    Gender = Gender.Female,
                    Role = Role.Patient,
                    IsActive = true,
                    DateOfBirth = new DateTime(1990, 6, 15),
                    JMBG = "1506990175099",
                    InsuranceNumber = "OSI-000000001",
                    Address = "Kočine Masline b. b.",
                    CityId = mostar?.Id ?? 2,
                    PhoneNumber = "+38761000001",
                    EmergencyContact = "+38761000002 (Family)",
                    IsInsured = true,
                    CreatedAt = DateTime.UtcNow
                }
            };

            await context.Patients.AddRangeAsync(patients);
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