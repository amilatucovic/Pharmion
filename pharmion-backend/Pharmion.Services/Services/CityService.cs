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
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class CityService : BaseCRUDService<CityResponse, CitySearchObject, City, CityUpsertRequest, CityUpsertRequest>, ICityService
    {
        private readonly PharmionDbContext _context;

        public CityService(PharmionDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<City> ApplyFilter(IQueryable<City> query, CitySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(pt => pt.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(pt => pt.Name.Contains(search.FTS));
            }
            return query;
        }

        protected override async Task BeforeInsert(City entity, CityUpsertRequest request)
        {
            if (await _context.Cities.AnyAsync(c => c.Name == request.Name))
                throw new UserException("City with this name already exists.");
        }

        protected override async Task BeforeUpdate(City entity, CityUpsertRequest request)
        {
            if (await _context.Cities.AnyAsync(c => c.Name == request.Name && c.Id != entity.Id))
                throw new UserException("City with this name already exists.");
        }

        protected override void MapUpdateToEntity(City entity, CityUpsertRequest request)
        {
            base.MapUpdateToEntity(entity, request);
        }

        protected override async Task BeforeDelete(City entity)
        {
            var hasTroops = await _context.Pharmacies.AnyAsync(t => t.CityId == entity.Id);
            var hasMembers = await _context.Patients.AnyAsync(m => m.CityId == entity.Id);
            if (hasTroops || hasMembers)
                throw new UserException("Cannot delete city: it is referenced by one or more Pharmacies or Patients.");
        }

        public override async Task<PagedResult<CityResponse>> GetAsync(CitySearchObject search)
        {
            var baseQuery = _context.Set<City>().AsQueryable();
            baseQuery = ApplyFilter(baseQuery, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await baseQuery.CountAsync();
            }

            var entities = await baseQuery.ToListAsync();

            var responseList = entities.Select(c => new CityResponse
            {
                Id = c.Id,
                Name = c.Name,
                PostalCode = c.PostalCode
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
                    "postalcode" => descending
                        ? responseList.OrderByDescending(x => x.PostalCode).ToList()
                        : responseList.OrderBy(x => x.PostalCode).ToList()
                };
            }

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
            {
                responseList = responseList
                    .Skip(search.Page.Value * search.PageSize.Value)
                    .Take(search.PageSize.Value)
                    .ToList();
            }

            return new PagedResult<CityResponse>
            {
                Items = responseList,
                TotalCount = totalCount
            };
        }
    }
}
