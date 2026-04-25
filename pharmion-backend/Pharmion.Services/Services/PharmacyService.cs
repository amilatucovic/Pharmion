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
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class PharmacyService:BaseCRUDService<PharmacyResponse, PharmacySearchObject, Pharmacy, PharmacyUpsertRequest, PharmacyUpsertRequest>, IPharmacyService
    {
        private readonly PharmionDbContext _context;

        public PharmacyService(PharmionDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        public override async Task<PharmacyResponse> CreateAsync(PharmacyUpsertRequest request)
        {
            var entity = new Pharmacy();
            MapInsertToEntity(entity, request);
            _context.Set<Pharmacy>().Add(entity);

            await BeforeInsert(entity, request);
            await _context.SaveChangesAsync();

            var createdEntity = await _context.Pharmacies
                .Include(p => p.City)
                .FirstOrDefaultAsync(p => p.Id == entity.Id);

            return MapToResponse(createdEntity);
        }

        public override async Task<PharmacyResponse?> UpdateAsync(int id, PharmacyUpsertRequest request)
        {
            var entity = await _context.Set<Pharmacy>().FindAsync(id);
            if (entity == null)
                return null;

            await BeforeUpdate(entity, request);
            MapUpdateToEntity(entity, request);
            await _context.SaveChangesAsync();

            var updatedEntity = await _context.Pharmacies
                .Include(p => p.City)
                .FirstOrDefaultAsync(p => p.Id == id);

            return MapToResponse(updatedEntity);
        }

        public override async Task<PharmacyResponse?> GetByIdAsync(int id)
        {
            var entity = await _context.Pharmacies
                .Include(p => p.City)
                .FirstOrDefaultAsync(p => p.Id == id);

            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected override IQueryable<Pharmacy> ApplyFilter(IQueryable<Pharmacy> query, PharmacySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(p => p.Name.Contains(search.Name));
            }

            if (search.CityId.HasValue)
            {
                query = query.Where(p => p.CityId == search.CityId.Value);
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(p => p.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(p => p.Name.Contains(search.FTS));
            }

            return query;
        }

        protected override async Task BeforeInsert(Pharmacy entity, PharmacyUpsertRequest request)
        {
            
            var cityExists = await _context.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
                throw new UserException("City with the specified ID does not exist.");

            if (await _context.Pharmacies.AnyAsync(p => p.Name == request.Name))
                throw new UserException("Pharmacy with this name already exists.");
        }

        protected override async Task BeforeUpdate(Pharmacy entity, PharmacyUpsertRequest request)
        {
            
            var cityExists = await _context.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
                throw new UserException("City with the specified ID does not exist.");

            
            if (await _context.Pharmacies.AnyAsync(p => p.Name == request.Name && p.Id != entity.Id))
                throw new UserException("Pharmacy with this name already exists.");
        }

        protected override void MapUpdateToEntity(Pharmacy entity, PharmacyUpsertRequest request)
        {
            base.MapUpdateToEntity(entity, request);
        }

        protected override async Task BeforeDelete(Pharmacy entity)
        {
            var hasInventoryItems = await _context.InventoryItems.AnyAsync(i => i.PharmacyId == entity.Id);
            var hasReservations = await _context.Reservations.AnyAsync(r => r.PharmacyId == entity.Id);

            if (hasInventoryItems || hasReservations)
                throw new UserException("Cannot delete pharmacy: it is referenced by one or more Inventory Items or Reservations.");
        }

        public override async Task<PagedResult<PharmacyResponse>> GetAsync(PharmacySearchObject search)
        {
            var baseQuery = _context.Set<Pharmacy>()
                .Include(p => p.City)
                .AsQueryable();

            baseQuery = ApplyFilter(baseQuery, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await baseQuery.CountAsync();
            }

            var entities = await baseQuery.ToListAsync();

            var responseList = entities.Select(p => new PharmacyResponse
            {
                Id = p.Id,
                Name = p.Name,
                Address = p.Address,
                CityId = p.CityId,
                CityName = p.City?.Name ?? string.Empty,
                IsActive = p.IsActive,
                WorkingHours = p.WorkingHours
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
                    "address" => descending
                        ? responseList.OrderByDescending(x => x.Address).ToList()
                        : responseList.OrderBy(x => x.Address).ToList(),
                    "cityname" => descending
                        ? responseList.OrderByDescending(x => x.CityName).ToList()
                        : responseList.OrderBy(x => x.CityName).ToList(),
                    "isactive" => descending
                        ? responseList.OrderByDescending(x => x.IsActive).ToList()
                        : responseList.OrderBy(x => x.IsActive).ToList(),
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

            return new PagedResult<PharmacyResponse>
            {
                Items = responseList,
                TotalCount = totalCount
            };
        }

        private PharmacyResponse MapToResponse(Pharmacy? p)
        {
            if (p == null) return null!;
            return new PharmacyResponse
            {
                Id = p.Id,
                Name = p.Name,
                Address = p.Address,
                CityId = p.CityId,
                CityName = p.City?.Name ?? string.Empty,
                IsActive = p.IsActive,
                WorkingHours = p.WorkingHours  
            };
        }
    }
}

