using Microsoft.AspNetCore.Http;

namespace Pharmion.Services.Interfaces
{
    public interface IImageUploadService
    {
        Task<string> UploadProductImageAsync(IFormFile file, int productId);
        Task<bool> DeleteProductImageAsync(string imageUrl);
    }
}
