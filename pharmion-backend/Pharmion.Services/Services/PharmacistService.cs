using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class PharmacistService : IPharmacistService
    {
        private readonly PharmionDbContext _context;

        public PharmacistService(PharmionDbContext context)
        {
            _context = context;
        }

        public async Task<PagedResult<PharmacistResponse>> GetAsync(PharmacistSearchObject search)
        {
            var query = _context.Pharmacists
                .Include(p => p.Pharmacy)
                    .ThenInclude(ph => ph.City)
                .AsQueryable();

            // Filters
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(p =>
                    (p.FirstName + " " + p.LastName).Contains(search.Name) ||
                    p.Username.Contains(search.Name) ||
                    p.Email.Contains(search.Name));
            }

            if (search.PharmacyId.HasValue)
                query = query.Where(p => p.PharmacyId == search.PharmacyId.Value);

            if (search.IsActive.HasValue)
                query = query.Where(p => p.IsActive == search.IsActive.Value);

            if (search.IsAdministrator.HasValue)
                query = query.Where(p => p.IsAdministrator == search.IsAdministrator.Value);

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync();

            query = query.OrderBy(p => p.LastName).ThenBy(p => p.FirstName);

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
                query = query.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);

            var pharmacists = await query.ToListAsync();

            return new PagedResult<PharmacistResponse>
            {
                Items = pharmacists.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<PharmacistResponse?> GetByIdAsync(int id)
        {
            var pharmacist = await _context.Pharmacists
                .Include(p => p.Pharmacy)
                    .ThenInclude(ph => ph.City)
                .FirstOrDefaultAsync(p => p.Id == id);

            return pharmacist == null ? null : MapToResponse(pharmacist);
        }

        public async Task<PharmacistResponse> CreateAsync(RegisterPharmacistRequest request)
        {
            // Validacije
            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new UserException("Username already exists.");

            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new UserException("Email already exists.");

            if (await _context.Pharmacists.AnyAsync(p => p.LicenseNumber == request.LicenseNumber))
                throw new UserException("License number already exists.");

            var pharmacyExists = await _context.Pharmacies.AnyAsync(p => p.Id == request.PharmacyId);
            if (!pharmacyExists)
                throw new UserException("Pharmacy not found.");

            var (passwordHash, passwordSalt) = CreatePasswordHash(request.Password);

            var pharmacist = new Pharmacist
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Username = request.Username,
                Email = request.Email,
                PasswordHash = passwordHash,
                PasswordSalt = passwordSalt,
                Gender = request.Gender,
                Role = Role.Pharmacist,
                IsActive = true,
                LicenseNumber = request.LicenseNumber,
                PharmacyId = request.PharmacyId,
                IsAdministrator = request.IsAdministrator,
                CreatedAt = DateTime.UtcNow
            };

            await _context.Pharmacists.AddAsync(pharmacist);
            await _context.SaveChangesAsync();

            // Reload sa relacijama
            var created = await _context.Pharmacists
                .Include(p => p.Pharmacy)
                    .ThenInclude(ph => ph.City)
                .FirstOrDefaultAsync(p => p.Id == pharmacist.Id);

            return MapToResponse(created!);
        }

        public async Task<PharmacistResponse?> UpdateAsync(int id, PharmacistUpdateRequest request)
        {
            var pharmacist = await _context.Pharmacists.FindAsync(id);
            if (pharmacist == null)
                return null;

            // Provjeri jedinstvenost emaila (isključi trenutnog korisnika)
            if (await _context.Users.AnyAsync(u => u.Email == request.Email && u.Id != id))
                throw new UserException("Email already in use by another user.");

            // Provjeri jedinstvenost licence (isključi trenutnog)
            if (await _context.Pharmacists.AnyAsync(p => p.LicenseNumber == request.LicenseNumber && p.Id != id))
                throw new UserException("License number already in use.");

            var pharmacyExists = await _context.Pharmacies.AnyAsync(p => p.Id == request.PharmacyId);
            if (!pharmacyExists)
                throw new UserException("Pharmacy not found.");

            pharmacist.FirstName = request.FirstName;
            pharmacist.LastName = request.LastName;
            pharmacist.Email = request.Email;
            pharmacist.LicenseNumber = request.LicenseNumber;
            pharmacist.PharmacyId = request.PharmacyId;
            pharmacist.IsAdministrator = request.IsAdministrator;
            pharmacist.IsActive = request.IsActive;
            pharmacist.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            var updated = await _context.Pharmacists
                .Include(p => p.Pharmacy)
                    .ThenInclude(ph => ph.City)
                .FirstOrDefaultAsync(p => p.Id == id);

            return MapToResponse(updated!);
        }

        public async Task<PharmacistResponse?> ToggleActiveAsync(int id)
        {
            var pharmacist = await _context.Pharmacists.FindAsync(id);
            if (pharmacist == null)
                return null;

            pharmacist.IsActive = !pharmacist.IsActive;
            pharmacist.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            var updated = await _context.Pharmacists
                .Include(p => p.Pharmacy)
                    .ThenInclude(ph => ph.City)
                .FirstOrDefaultAsync(p => p.Id == id);

            return MapToResponse(updated!);
        }


        private PharmacistResponse MapToResponse(Pharmacist p) => new PharmacistResponse
        {
            Id = p.Id,
            FirstName = p.FirstName,
            LastName = p.LastName,
            Username = p.Username,
            Email = p.Email,
            LicenseNumber = p.LicenseNumber,
            PharmacyId = p.PharmacyId,
            PharmacyName = p.Pharmacy?.Name ?? string.Empty,
            PharmacyCity = p.Pharmacy?.City?.Name ?? string.Empty,
            IsAdministrator = p.IsAdministrator,
            IsActive = p.IsActive,
            Gender = p.Gender,
            CreatedAt = p.CreatedAt,
            LastLoginAt = p.LastLoginAt
        };

        private static (string hash, string salt) CreatePasswordHash(string password)
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