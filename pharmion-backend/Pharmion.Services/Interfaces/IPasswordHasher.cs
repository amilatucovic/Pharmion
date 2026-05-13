namespace Pharmion.Services.Interfaces
{
    public interface IPasswordHasher
    {
        (string hash, string salt) CreatePasswordHash(string password);
        bool VerifyPasswordHash(string password, string storedHash, string storedSalt);
    }
}
