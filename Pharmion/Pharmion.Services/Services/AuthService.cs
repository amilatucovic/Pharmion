using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using System;
using System.IdentityModel.Tokens.Jwt;
using System.Linq;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class AuthService : IAuthService
    {
        private readonly PharmionDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthService(PharmionDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        public async Task<LoginResponse> LoginAsync(LoginRequest request, string ipAddress)
        {
            
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username == request.Username && u.IsActive);

            if (user == null)
                throw new UserException("Invalid username or password");

            
            if (!VerifyPasswordHash(request.Password, user.PasswordHash, user.PasswordSalt))
                throw new UserException("Invalid username or password");

            user.LastLoginAt = DateTime.UtcNow;

            var accessToken = GenerateAccessToken(user);
            var refreshToken = await GenerateRefreshTokenAsync(user.Id, ipAddress);

            await _context.SaveChangesAsync();
            return await BuildLoginResponse(user, accessToken, refreshToken);
        }

        public async Task<LoginResponse> RefreshTokenAsync(string refreshToken, string ipAddress)
        {
            var storedToken = await _context.RefreshTokens
                .Include(rt => rt.User)
                .FirstOrDefaultAsync(rt => rt.Token == refreshToken);

            if (storedToken == null)
                throw new UserException("Invalid refresh token");

            if (!storedToken.IsActive)
                throw new UserException("Refresh token is no longer valid");

            var user = storedToken.User;
            if (user == null || !user.IsActive)
                throw new UserException("User not found or inactive");

            storedToken.IsRevoked = true;
            storedToken.RevokedAt = DateTime.UtcNow;
            storedToken.RevokedByIp = ipAddress;

            var newAccessToken = GenerateAccessToken(user);
            var newRefreshToken = await GenerateRefreshTokenAsync(user.Id, ipAddress);

            storedToken.ReplacedByToken = newRefreshToken.Token;

            await _context.SaveChangesAsync();
            return await BuildLoginResponse(user, newAccessToken, newRefreshToken);
        }

        public async Task RevokeTokenAsync(string refreshToken, string ipAddress)
        {
            var token = await _context.RefreshTokens
                .FirstOrDefaultAsync(rt => rt.Token == refreshToken);

            if (token == null)
                throw new UserException("Invalid refresh token");

            if (!token.IsActive)
                throw new UserException("Token is already revoked");

            token.IsRevoked = true;
            token.RevokedAt = DateTime.UtcNow;
            token.RevokedByIp = ipAddress;

            await _context.SaveChangesAsync();
        }

        public async Task<LoginResponse> RegisterPatientAsync(RegisterPatientRequest request, string ipAddress)
        {
            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
                throw new UserException("Username already exists");

            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                throw new UserException("Email already exists");

            if (await _context.Patients.AnyAsync(p => p.JMBG == request.JMBG))
                throw new UserException("JMBG already exists");

            var cityExists = await _context.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
                throw new UserException("Invalid city");

            var (passwordHash, passwordSalt) = CreatePasswordHash(request.Password);
            var patient = new Patient
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Username = request.Username,
                Email = request.Email,
                PasswordHash = passwordHash,
                PasswordSalt = passwordSalt,
                Gender = request.Gender,
                Role = Role.Patient,
                IsActive = true,
                DateOfBirth = request.DateOfBirth,
                JMBG = request.JMBG,
                InsuranceNumber = request.InsuranceNumber,
                Address = request.Address,
                CityId = request.CityId,
                PhoneNumber = request.PhoneNumber,
                EmergencyContact = request.EmergencyContact,
                IsInsured = request.IsInsured,
                CreatedAt = DateTime.UtcNow
            };

            await _context.Patients.AddAsync(patient);
            await _context.SaveChangesAsync();

            return await LoginAsync(new LoginRequest
            {
                Username = request.Username,
                Password = request.Password
            }, ipAddress);
        }

        public async Task<bool> ChangePasswordAsync(int userId, string oldPassword, string newPassword)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null)
                throw new UserException("User not found");

            if (!VerifyPasswordHash(oldPassword, user.PasswordHash, user.PasswordSalt))
                throw new UserException("Current password is incorrect");

            var (passwordHash, passwordSalt) = CreatePasswordHash(newPassword);

            user.PasswordHash = passwordHash;
            user.PasswordSalt = passwordSalt;
            user.UpdatedAt = DateTime.UtcNow;

            var userTokens = await _context.RefreshTokens
                .Where(rt => rt.UserId == userId && rt.IsActive)
                .ToListAsync();

            foreach (var token in userTokens)
            {
                token.IsRevoked = true;
                token.RevokedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();

            return true;
        }

        private string GenerateAccessToken(User user)
        {
            var jwtSecret = _configuration["JwtSettings:Secret"];
            var issuer = _configuration["JwtSettings:Issuer"];
            var audience = _configuration["JwtSettings:Audience"];
            var expiryMinutes = int.Parse(_configuration["JwtSettings:AccessTokenExpiryInMinutes"] ?? "15");

            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecret));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, user.Username),
                new Claim(JwtRegisteredClaimNames.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role.ToString()),
                new Claim(ClaimTypes.Name, $"{user.FirstName} {user.LastName}"),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            var token = new JwtSecurityToken(
                issuer: issuer,
                audience: audience,
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(expiryMinutes),
                signingCredentials: credentials
            );

            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        private async Task<RefreshToken> GenerateRefreshTokenAsync(int userId, string ipAddress)
        {
            var expiryDays = int.Parse(_configuration["JwtSettings:RefreshTokenExpiryInDays"] ?? "7");
            var randomBytes = new byte[64];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(randomBytes);
            }

            var refreshToken = new RefreshToken
            {
                UserId = userId,
                Token = Convert.ToBase64String(randomBytes),
                ExpiresAt = DateTime.UtcNow.AddDays(expiryDays),
                CreatedAt = DateTime.UtcNow,
                CreatedByIp = ipAddress
            };

            await _context.RefreshTokens.AddAsync(refreshToken);
            await RemoveOldRefreshTokensAsync(userId);
            return refreshToken;
        }

        private async Task RemoveOldRefreshTokensAsync(int userId)
        {
            var oldTokens = await _context.RefreshTokens
                .Where(rt => rt.UserId == userId
                          && rt.CreatedAt.AddDays(30) < DateTime.UtcNow)
                .ToListAsync();

            if (oldTokens.Any())
            {
                _context.RefreshTokens.RemoveRange(oldTokens);
            }
        }

        private async Task<LoginResponse> BuildLoginResponse(User user, string accessToken, RefreshToken refreshToken)
        {
            var accessTokenExpiryMinutes = int.Parse(_configuration["JwtSettings:AccessTokenExpiryInMinutes"] ?? "15");

            var response = new LoginResponse
            {
                UserId = user.Id,
                Username = user.Username,
                Email = user.Email,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Role = user.Role,
                AccessToken = accessToken,
                RefreshToken = refreshToken.Token,
                AccessTokenExpiresAt = DateTime.UtcNow.AddMinutes(accessTokenExpiryMinutes),
                RefreshTokenExpiresAt = refreshToken.ExpiresAt
            };

            if (user.Role == Role.Pharmacist)
            {
                var pharmacist = await _context.Pharmacists.FindAsync(user.Id);
                if (pharmacist != null)
                {
                    response.IsAdministrator = pharmacist.IsAdministrator;
                    response.PharmacyId = pharmacist.PharmacyId;
                }
            }
            else if (user.Role == Role.Patient)
            {
                var patient = await _context.Patients.FindAsync(user.Id);
                if (patient != null)
                {
                    response.CityId = patient.CityId;
                }
            }

            return response;
        }

        private (string hash, string salt) CreatePasswordHash(string password)
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

        private bool VerifyPasswordHash(string password, string storedHash, string storedSalt)
        {
            byte[] saltBytes = Convert.FromBase64String(storedSalt);

            using (var hmac = new HMACSHA512(saltBytes))
            {
                byte[] computedHash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
                string computedHashString = Convert.ToBase64String(computedHash);

                return computedHashString == storedHash;
            }
        }
    }
}