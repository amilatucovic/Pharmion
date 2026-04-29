using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Pharmion.Services.Interfaces;

namespace Pharmion.Services.Services
{
    public class ImageUploadService : IImageUploadService
    {
        private readonly string _uploadPath;
        private readonly string _baseUrl;
        private readonly ILogger<ImageUploadService> _logger;

        public ImageUploadService(IWebHostEnvironment env, IConfiguration configuration, ILogger<ImageUploadService> logger)
        {
            _uploadPath = Path.Combine(env.WebRootPath, "images", "products");
            _baseUrl = configuration["AppSettings:BaseUrl"]
               ?? throw new InvalidOperationException("AppSettings:BaseUrl not configured");

            if (!Directory.Exists(_uploadPath))
            {
                Directory.CreateDirectory(_uploadPath);
            }

            _logger = logger;
        }

        public async Task<string> UploadProductImageAsync(IFormFile file, int productId)
        {
            if (file == null || file.Length == 0)
                throw new ArgumentException("Invalid file");


            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(extension))
                throw new ArgumentException("Only image files (jpg, jpeg, png, webp) are allowed");

           
            var allowedMimeTypes = new[] { "image/jpeg", "image/png", "image/webp", "application/octet-stream" };
            if (!allowedMimeTypes.Contains(file.ContentType.ToLowerInvariant()))
                throw new ArgumentException("Invalid file type");

            
            using var stream = file.OpenReadStream();
            if (!await IsValidImageAsync(stream))
                throw new ArgumentException("File content does not match a valid image format");
            stream.Position = 0; 

            
            if (file.Length > 5 * 1024 * 1024)
                throw new ArgumentException("File size must not exceed 5MB");

            var fileName = $"product-{productId}-{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(_uploadPath, fileName);

            using var fileStream = new FileStream(filePath, FileMode.Create);
            await stream.CopyToAsync(fileStream);

            return $"/images/products/{fileName}";
        }

        private static async Task<bool> IsValidImageAsync(Stream stream)
        {
            var header = new byte[12];
            var read = await stream.ReadAsync(header, 0, 12);
            if (read < 4) return false;

            
            if (header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF)
                return true;

           
            if (header[0] == 0x89 && header[1] == 0x50 &&
                header[2] == 0x4E && header[3] == 0x47)
                return true;

            
            if (read >= 12 &&
                header[0] == 0x52 && header[1] == 0x49 &&
                header[2] == 0x46 && header[3] == 0x46 &&
                header[8] == 0x57 && header[9] == 0x45 &&
                header[10] == 0x42 && header[11] == 0x50)
                return true;

            return false;
        }

        public Task<bool> DeleteProductImageAsync(string imageUrl)
        {
            if (string.IsNullOrEmpty(imageUrl) || imageUrl == "/images/products/default-product.jpg")
                return Task.FromResult(false);

            try
            {
                var fileName = Path.GetFileName(imageUrl);
                var filePath = Path.Combine(_uploadPath, fileName);

                if (File.Exists(filePath))
                {
                    File.Delete(filePath);
                    return Task.FromResult(true);
                }
            }
            catch(Exception ex)
            {
                _logger.LogError(ex, "Failed to delete image at {ImageUrl}", imageUrl);
            }

            return Task.FromResult(false);
        }
    }
}