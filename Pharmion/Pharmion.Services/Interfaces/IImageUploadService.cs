using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;

namespace Pharmion.Services.Interfaces
{
    public interface IImageUploadService
    {
        Task<string> UploadProductImageAsync(IFormFile file, int productId);
        Task<bool> DeleteProductImageAsync(string imageUrl);
    }
}
