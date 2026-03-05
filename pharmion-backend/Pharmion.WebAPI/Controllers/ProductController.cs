using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Interfaces;

namespace Pharmion.WebAPI.Controllers
{
    [Route("[controller]")]
    [ApiController]
    [Authorize]
    public class ProductController : BaseCRUDController<ProductResponse, ProductSearchObject, ProductInsertRequest, ProductUpdateRequest>
    {
        private readonly IProductService _productService;
        private readonly IImageUploadService _imageUploadService;

        public ProductController(IProductService productService, IImageUploadService imageUploadService) : base(productService)
        {
            _productService = productService;
            _imageUploadService = imageUploadService;
        }

        [HttpPost]
        [Authorize(Policy = "AdminOnly")]
        public override Task<IActionResult> Create([FromBody] ProductInsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override Task<IActionResult> Update(int id, [FromBody] ProductUpdateRequest request)
        {
            return base.Update(id, request);
        }

        [HttpDelete("{id}")]
        [Authorize(Policy = "AdminOnly")]
        public override Task<IActionResult> Delete(int id)
        {
            return base.Delete(id);
        }

        [HttpPost("{id}/image")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> UploadProductImage(int id, IFormFile file)
        {
            try
            {
                var product = await _productService.GetByIdAsync(id);
                if (product == null)
                    return NotFound(new { message = "Product not found" });

                var newImageUrl = await _imageUploadService.UploadProductImageAsync(file, id);

                if (!string.IsNullOrEmpty(product.ImageUrl) &&
                    product.ImageUrl != "/images/products/default-product.jpg")
                {
                    await _imageUploadService.DeleteProductImageAsync(product.ImageUrl);
                }

                await _productService.UpdateImageUrlAsync(id, newImageUrl);

                return Ok(new
                {
                    imageUrl = newImageUrl,
                    message = "Image uploaded successfully"
                });
            }
            catch (ArgumentException ex)
            {
                return BadRequest(new { message = ex.Message });
            }
        }

        [HttpDelete("{id}/image")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> DeleteProductImage(int id)
        {
            try
            {
                var product = await _productService.GetByIdAsync(id);
                if (product == null)
                    return NotFound(new { message = "Product not found" });

                if (string.IsNullOrEmpty(product.ImageUrl) ||
                    product.ImageUrl == "/images/products/default-product.jpg")
                    return BadRequest(new { message = "Product has no custom image" });

                await _imageUploadService.DeleteProductImageAsync(product.ImageUrl);

                await _productService.UpdateImageUrlAsync(id, "/images/products/default-product.jpg");

                return Ok(new { message = "Image deleted, reverted to default" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error deleting image", error = ex.Message });
            }
        }
    }
}
