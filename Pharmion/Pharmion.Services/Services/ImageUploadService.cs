using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Pharmion.Services.Interfaces;
using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class ImageUploadService : IImageUploadService
    {
        private readonly string _uploadPath;
        private readonly string _baseUrl;

        public ImageUploadService(IWebHostEnvironment env, IConfiguration configuration)
        {
            _uploadPath = Path.Combine(env.WebRootPath, "images", "products");
            _baseUrl = configuration["AppSettings:BaseUrl"] ?? "https://localhost:5081";

            if (!Directory.Exists(_uploadPath))
            {
                Directory.CreateDirectory(_uploadPath);
            }
        }

        public async Task<string> UploadProductImageAsync(IFormFile file, int productId)
        {
            if (file == null || file.Length == 0)
                throw new ArgumentException("Invalid file");

            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

            if (!allowedExtensions.Contains(extension))
                throw new ArgumentException("Only image files (jpg, jpeg, png, webp) are allowed");

            if (file.Length > 5 * 1024 * 1024)
                throw new ArgumentException("File size must not exceed 5MB");

            var fileName = $"product-{productId}-{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(_uploadPath, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            return $"/images/products/{fileName}";
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
            catch
            {
                Console.WriteLine($"Failed to delete image at {imageUrl}");
            }

            return Task.FromResult(false);
        }
    }
}