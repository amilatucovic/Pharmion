using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;

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
            if (entity.Type == ProductType.Medication && request.MedicationCategoryId.HasValue)
            {
                entity.MedicationDetails = new MedicationDetail
                {
                    ATCCode = request.AtcCode,
                    RequiresColdChain = request.RequiresColdChain,
                    MedicationCategoryId = request.MedicationCategoryId.Value,
                    PharmacologicalCategoryId = request.PharmacologicalCategoryId,
                    CreatedAt = DateTime.UtcNow
                };
            }
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
            if (entity.Type == ProductType.Medication && request.MedicationCategoryId.HasValue)
            {
                await _context.Entry(entity)
                    .Reference(p => p.MedicationDetails)
                    .LoadAsync();

                if (entity.MedicationDetails == null)
                {
                    entity.MedicationDetails = new MedicationDetail
                    {
                        ProductId = entity.Id,
                        ATCCode = request.AtcCode,
                        RequiresColdChain = request.RequiresColdChain,
                        MedicationCategoryId = request.MedicationCategoryId.Value,
                        PharmacologicalCategoryId = request.PharmacologicalCategoryId,
                        CreatedAt = DateTime.UtcNow
                    };
                }
                else
                {
                    entity.MedicationDetails.ATCCode = request.AtcCode;
                    entity.MedicationDetails.RequiresColdChain = request.RequiresColdChain;
                    entity.MedicationDetails.MedicationCategoryId = request.MedicationCategoryId.Value;
                    entity.MedicationDetails.PharmacologicalCategoryId = request.PharmacologicalCategoryId;
                    entity.MedicationDetails.UpdatedAt = DateTime.UtcNow;
                }
            }
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
            var baseQuery = _context.Set<Product>()
                .Include(p => p.MedicationDetails)
                    .ThenInclude(md => md.MedicationCategory)
                .Include(p => p.MedicationDetails)
                    .ThenInclude(md => md.PharmacologicalCategory)
                .Include(p => p.SupplementDetails)
                .AsQueryable();

            baseQuery = ApplyFilter(baseQuery, search);

            if (!string.IsNullOrWhiteSpace(search.OrderBy))
            {
                var orderBy = search.OrderBy.ToLower();
                var descending = orderBy.StartsWith("-");
                if (descending) orderBy = orderBy.Substring(1);

                baseQuery = orderBy switch
                {
                    "name" => descending
                        ? baseQuery.OrderByDescending(x => x.Name)
                        : baseQuery.OrderBy(x => x.Name),
                    "price" => descending
                        ? baseQuery.OrderByDescending(x => x.Price)
                        : baseQuery.OrderBy(x => x.Price),
                    "createdat" => descending
                        ? baseQuery.OrderByDescending(x => x.CreatedAt)
                        : baseQuery.OrderBy(x => x.CreatedAt),
                    _ => baseQuery
                };
            }
            else
            {
                baseQuery = baseQuery.OrderBy(x => x.Name); 
            }

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await baseQuery.CountAsync();

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
                baseQuery = baseQuery
                    .Skip(search.Page.Value * search.PageSize.Value)
                    .Take(search.PageSize.Value);

            var entities = await baseQuery.ToListAsync();

            return new PagedResult<ProductResponse>
            {
                Items = entities.Select(p => new ProductResponse
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
                    Description = p.Description,
                    Unit = p.Unit,
                    PackageSize = p.PackageSize,
                    Price = p.Price,
                    SideEffects = p.SideEffects,
                    InstructionsForUse = p.InstructionsForUse,
                    Contraindications = p.Contraindications,
                    ImageUrl = p.ImageUrl,
                    MedicationCategoryId = p.MedicationDetails?.MedicationCategoryId,
                    MedicationCategoryName = p.MedicationDetails?.MedicationCategory?.Name,
                    PharmacologicalCategoryId = p.MedicationDetails?.PharmacologicalCategoryId,
                    PharmacologicalCategoryName = p.MedicationDetails?.PharmacologicalCategory?.Name,
                    AtcCode = p.MedicationDetails?.ATCCode,
                    RequiresColdChain = p.MedicationDetails?.RequiresColdChain ?? false,
                    CreatedAt = p.CreatedAt,
                    UpdatedAt = p.UpdatedAt
                }).ToList(),
                TotalCount = totalCount
            };
        }
    }
}