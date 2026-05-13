using System.Security.Cryptography;
using Pharmion.Services.Interfaces;

namespace Pharmion.Services.Services
{
    public class PasswordHasher : IPasswordHasher
    {
        public (string hash, string salt) CreatePasswordHash(string password)
        {
            byte[] saltBytes = new byte[16];
            using (var rng = RandomNumberGenerator.Create())
                rng.GetBytes(saltBytes);

            string salt = Convert.ToBase64String(saltBytes);

            var pbkdf2 = new Rfc2898DeriveBytes(
                password, saltBytes, 100000, HashAlgorithmName.SHA256);
            string hash = Convert.ToBase64String(pbkdf2.GetBytes(32));

            return (hash, salt);
        }

        public bool VerifyPasswordHash(string password, string storedHash, string storedSalt)
        {
            byte[] saltBytes = Convert.FromBase64String(storedSalt);

            var pbkdf2 = new Rfc2898DeriveBytes(
                password, saltBytes, 100000, HashAlgorithmName.SHA256);
            string computedHash = Convert.ToBase64String(pbkdf2.GetBytes(32));

            return computedHash == storedHash;
        }
    }
}