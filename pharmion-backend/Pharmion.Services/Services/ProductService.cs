using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class ProductService : BaseCRUDService<ProductResponse, ProductSearchObject, Product, ProductInsertRequest, ProductUpdateRequest>, IProductService
    {
        private readonly PharmionDbContext _context;

        public ProductService(PharmionDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<Product> ApplyFilter(IQueryable<Product> query, ProductSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(p => p.Name.Contains(search.Name));
            }

            if (search.Type.HasValue)
            {
                query = query.Where(p => p.Type == search.Type.Value);
            }

            if (search.IsPrescriptionRequired.HasValue)
            {
                query = query.Where(p => p.IsPrescriptionRequired == search.IsPrescriptionRequired.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(p => p.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.Manufacturer))
            {
                query = query.Where(p => p.Manufacturer != null && p.Manufacturer.Contains(search.Manufacturer));
            }

            if (search.MinPrice.HasValue)
            {
                query = query.Where(p => p.Price >= search.MinPrice.Value);
            }

            if (search.MaxPrice.HasValue)
            {
                query = query.Where(p => p.Price <= search.MaxPrice.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(p => p.Name.Contains(search.FTS)
                                      || (p.Manufacturer != null && p.Manufacturer.Contains(search.FTS))
                                      || (p.SKU != null && p.SKU.Contains(search.FTS))
                                      || (p.Barcode != null && p.Barcode.Contains(search.FTS)));
            }

            return query;
        }

        protected override async Task BeforeInsert(Product entity, ProductInsertRequest request)
        {
            if (!string.IsNullOrEmpty(request.SKU))
            {
                if (await _context.Products.AnyAsync(p => p.SKU == request.SKU))
                    throw new UserException("Product with this SKU already exists.");
            }

            if (!string.IsNullOrEmpty(request.Barcode))
            {
                if (await _context.Products.AnyAsync(p => p.Barcode == request.Barcode))
                    throw new UserException("Product with this barcode already exists.");
            }

            entity.ImageUrl = "/images/products/default-product.jpg";
            entity.CreatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(Product entity, ProductUpdateRequest request)
        {
            
            if (!string.IsNullOrEmpty(request.SKU))
            {
                if (await _context.Products.AnyAsync(p => p.SKU == request.SKU && p.Id != entity.Id))
                    throw new UserException("Product with this SKU already exists.");
            }

            
            if (!string.IsNullOrEmpty(request.Barcode))
            {
                if (await _context.Products.AnyAsync(p => p.Barcode == request.Barcode && p.Id != entity.Id))
                    throw new UserException("Product with this barcode already exists.");
            }

            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override void MapUpdateToEntity(Product entity, ProductUpdateRequest request)
        {
            base.MapUpdateToEntity(entity, request);
        }

        protected override async Task BeforeDelete(Product entity)
        {
           
            var hasInventoryItems = await _context.InventoryItems.AnyAsync(i => i.ProductId == entity.Id);
            if (hasInventoryItems)
                throw new UserException("Cannot delete product: it exists in pharmacy inventories.");

            
            var hasReservationItems = await _context.ReservationItems.AnyAsync(ri => ri.ProductId == entity.Id);
            if (hasReservationItems)
                throw new UserException("Cannot delete product: it is referenced in reservations.");

            var hasPrescriptionItems = await _context.PrescriptionItems.AnyAsync(pi => pi.ProductId == entity.Id);
            if (hasPrescriptionItems)
                throw new UserException("Cannot delete product: it is referenced in prescriptions.");
        }

        public async Task UpdateImageUrlAsync(int productId, string imageUrl)
        {
            var product = await _context.Products.FindAsync(productId);

            if (product == null)
                throw new UserException("Product not found");

            product.ImageUrl = imageUrl;
            product.UpdatedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();
        }

        public override async Task<PagedResult<ProductResponse>> GetAsync(ProductSearchObject search)
        {
            var baseQuery = _context.Set<Product>().AsQueryable();

            baseQuery = ApplyFilter(baseQuery, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await baseQuery.CountAsync();
            }

            var entities = await baseQuery.ToListAsync();

            var responseList = entities.Select(p => new ProductResponse
            {
                Id = p.Id,
                Name = p.Name,
                Type = p.Type,
                TypeName = p.Type.ToString(),
                IsPrescriptionRequired = p.IsPrescriptionRequired,
                IsActive = p.IsActive,
                SKU = p.SKU,
                Barcode = p.Barcode,
                Manufacturer = p.Manufacturer,
                Unit = p.Unit,
                PackageSize = p.PackageSize,
                Price = p.Price,
                SideEffects = p.SideEffects,
                InstructionsForUse = p.InstructionsForUse,
                Contraindications = p.Contraindications,
                ImageUrl = p.ImageUrl,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            }).ToList();

            if (!string.IsNullOrWhiteSpace(search.OrderBy))
            {
                var orderBy = search.OrderBy.ToLower();
                var descending = orderBy.StartsWith("-");
                if (descending)
                {
                    orderBy = orderBy.Substring(1);
                }

                responseList = orderBy switch
                {
                    "name" => descending
                        ? responseList.OrderByDescending(x => x.Name).ToList()
                        : responseList.OrderBy(x => x.Name).ToList(),
                    "price" => descending
                        ? responseList.OrderByDescending(x => x.Price).ToList()
                        : responseList.OrderBy(x => x.Price).ToList(),
                    "manufacturer" => descending
                        ? responseList.OrderByDescending(x => x.Manufacturer).ToList()
                        : responseList.OrderBy(x => x.Manufacturer).ToList(),
                    "createdat" => descending
                        ? responseList.OrderByDescending(x => x.CreatedAt).ToList()
                        : responseList.OrderBy(x => x.CreatedAt).ToList(),
                    _ => responseList
                };
            }

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
            {
                responseList = responseList
                    .Skip(search.Page.Value * search.PageSize.Value)
                    .Take(search.PageSize.Value)
                    .ToList();
            }

            return new PagedResult<ProductResponse>
            {
                Items = responseList,
                TotalCount = totalCount
            };
        }
    }
}