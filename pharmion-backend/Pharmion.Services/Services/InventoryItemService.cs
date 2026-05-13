using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;


namespace Pharmion.Services.Services
{
    public class InventoryItemService
        : BaseCRUDService<InventoryItemResponse, InventoryItemSearchObject, InventoryItem, InventoryItemInsertRequest, InventoryItemUpdateRequest>,
          IInventoryItemService
    {
        private readonly PharmionDbContext _context;

        public InventoryItemService(PharmionDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<InventoryItem> ApplyFilter(IQueryable<InventoryItem> query, InventoryItemSearchObject search)
        {
            if (search.PharmacyId.HasValue)
                query = query.Where(i => i.PharmacyId == search.PharmacyId.Value);

            if (search.ProductId.HasValue)
                query = query.Where(i => i.ProductId == search.ProductId.Value);

            if (!string.IsNullOrEmpty(search.ProductName))
                query = query.Where(i => i.Product != null && i.Product.Name.Contains(search.ProductName));

            if (search.LowStock == true)
                query = query.Where(i => (i.QuantityOnHand - i.ReservedQuantity) <= i.ReorderLevel);

            if (search.ExpiringSoon == true)
            {
                var threshold = DateTime.UtcNow.AddDays(30);
                query = query.Where(i => i.ExpirationDate <= threshold);
            }
            if (search.CityId.HasValue)
                query = query.Where(i => i.Pharmacy.City.Id == search.CityId.Value);

            return query;
        }

        protected override async Task BeforeInsert(InventoryItem entity, InventoryItemInsertRequest request)
        {
            var pharmacyExists = await _context.Pharmacies.AnyAsync(p => p.Id == request.PharmacyId);
            if (!pharmacyExists)
                throw new UserException("Pharmacy not found.");

            var productExists = await _context.Products.AnyAsync(p => p.Id == request.ProductId);
            if (!productExists)
                throw new UserException("Product not found.");

           
            var alreadyExists = await _context.InventoryItems
                .AnyAsync(i => i.PharmacyId == request.PharmacyId && i.ProductId == request.ProductId);
            if (alreadyExists)
                throw new UserException("This product already exists in the inventory of the selected pharmacy.");

            if (request.ExpirationDate <= DateTime.UtcNow)
                throw new UserException("Expiration date must be in the future.");

            entity.ReservedQuantity = 0;
            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(InventoryItem entity, InventoryItemUpdateRequest request)
        {
            if (request.ExpirationDate <= DateTime.UtcNow)
                throw new UserException("Expiration date must be in the future.");

            if (request.QuantityOnHand < entity.ReservedQuantity)
                throw new UserException($"Quantity on hand cannot be less than reserved quantity ({entity.ReservedQuantity}).");

            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeDelete(InventoryItem entity)
        {
            if (entity.ReservedQuantity > 0)
                throw new UserException("Cannot delete inventory item: there are active reservations for this item.");
        }

        public override async Task<PagedResult<InventoryItemResponse>> GetAsync(InventoryItemSearchObject search)
        {
            var baseQuery = _context.Set<InventoryItem>()
                .Include(i => i.Product)
                .Include(i => i.Pharmacy)
                    .ThenInclude(p => p.City)
                .AsQueryable();

            baseQuery = ApplyFilter(baseQuery, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await baseQuery.CountAsync();

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
            {
                var pageSize = Math.Min(search.PageSize.Value, 100);
                baseQuery = baseQuery
                    .Skip(search.Page.Value * pageSize)
                    .Take(pageSize);
            }

            var entities = await baseQuery.ToListAsync();

            return new PagedResult<InventoryItemResponse>
            {
                Items = entities.Select(i => new InventoryItemResponse
                {
                    Id = i.Id,
                    PharmacyId = i.PharmacyId,
                    PharmacyName = i.Pharmacy?.Name ?? string.Empty,
                    ProductId = i.ProductId,
                    ProductName = i.Product?.Name ?? string.Empty,
                    ProductSku = i.Product?.SKU,
                    ProductImageUrl = i.Product?.ImageUrl,
                    QuantityOnHand = i.QuantityOnHand,
                    ReservedQuantity = i.ReservedQuantity,
                    ReorderLevel = i.ReorderLevel,
                    ExpirationDate = i.ExpirationDate,
                    UpdatedAt = i.UpdatedAt,
                }).ToList(),
                TotalCount = totalCount
            };
        }

        public async Task<List<PublicInventoryItemResponse>> GetPublicAsync(InventoryItemSearchObject search)
        {
            var query = _context.Set<InventoryItem>()
                .Include(i => i.Product)
                .Include(i => i.Pharmacy)
                .AsQueryable();

            query = ApplyFilter(query, search);

            var entities = await query.ToListAsync();

            return entities.Select(i => new PublicInventoryItemResponse
            {
                PharmacyId = i.PharmacyId,
                PharmacyName = i.Pharmacy?.Name ?? string.Empty,
                ProductId = i.ProductId,
                ProductName = i.Product?.Name ?? string.Empty,
                ProductImageUrl = i.Product?.ImageUrl,
                IsAvailable = (i.QuantityOnHand - i.ReservedQuantity) > 0
            }).ToList();
        }
    }
}