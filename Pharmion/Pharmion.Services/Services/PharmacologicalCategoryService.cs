using MapsterMapper;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Database;
using Pharmion.Services.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace Pharmion.Services.Services
{
    public class PharmacologicalCategoryService : BaseCRUDService<PharmacologicalCategoryResponse, PharmacologicalCategorySearchObject, PharmacologicalCategory, PharmacologicalCategoryUpsertRequest, PharmacologicalCategoryUpsertRequest>, IPharmacologicalCategoryService
    {
        private readonly PharmionDbContext _context;

        public PharmacologicalCategoryService(PharmionDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<PharmacologicalCategory> ApplyFilter(IQueryable<PharmacologicalCategory> query, PharmacologicalCategorySearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Code))
            {
                query = query.Where(pc => pc.Code.Contains(search.Code));
            }

            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(pc => pc.Name.Contains(search.Name));
            }

            if (search.IsActive.HasValue)
            {
                query = query.Where(pc => pc.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(pc => pc.Code.Contains(search.FTS)
                                       || pc.Name.Contains(search.FTS)
                                       || pc.Description.Contains(search.FTS));
            }

            return query;
        }

        private async Task ValidateNameUnique(string name, int? id = null)
        {
            if (await _context.PharmacologicalCategories.AnyAsync(pc => pc.Name == name && pc.Id != id))
                throw new UserException("Medication category with this name already exists.");
        }

        private async Task ValidateCodeUnique(string code, int? id = null)
        {
            if (await _context.PharmacologicalCategories.AnyAsync(pc => pc.Code == code && pc.Id != id))
                throw new UserException("Medication category with this code already exists.");
        }

        protected override async Task BeforeInsert(PharmacologicalCategory entity, PharmacologicalCategoryUpsertRequest request)
        {
            await ValidateCodeUnique(request.Code);

            await ValidateNameUnique(request.Name);

            entity.CreatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(PharmacologicalCategory entity, PharmacologicalCategoryUpsertRequest request)
        {
            await ValidateCodeUnique(request.Code, entity.Id);

            await ValidateNameUnique(request.Name, entity.Id);

            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override void MapUpdateToEntity(PharmacologicalCategory entity, PharmacologicalCategoryUpsertRequest request)
        {
            base.MapUpdateToEntity(entity, request);
        }

        protected override async Task BeforeDelete(PharmacologicalCategory entity)
        {
            var hasMedications = await _context.MedicationDetails.AnyAsync(md => md.PharmacologicalCategoryId == entity.Id);

            if (hasMedications)
                throw new UserException("Cannot delete pharmacological category: it is assigned to one or more medications.");
        }

        public override async Task<PagedResult<PharmacologicalCategoryResponse>> GetAsync(PharmacologicalCategorySearchObject search)
        {
            var baseQuery = _context.Set<PharmacologicalCategory>().AsQueryable();

            baseQuery = ApplyFilter(baseQuery, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await baseQuery.CountAsync();
            }

            var entities = await baseQuery.ToListAsync();

            var responseList = entities.Select(pc => new PharmacologicalCategoryResponse
            {
                Id = pc.Id,
                Code = pc.Code,
                Name = pc.Name,
                Description = pc.Description,
                IsActive = pc.IsActive,
                CreatedAt = pc.CreatedAt,
                UpdatedAt = pc.UpdatedAt
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
                    "code" => descending
                        ? responseList.OrderByDescending(x => x.Code).ToList()
                        : responseList.OrderBy(x => x.Code).ToList(),
                    "name" => descending
                        ? responseList.OrderByDescending(x => x.Name).ToList()
                        : responseList.OrderBy(x => x.Name).ToList(),
                    "isactive" => descending
                        ? responseList.OrderByDescending(x => x.IsActive).ToList()
                        : responseList.OrderBy(x => x.IsActive).ToList(),
                    "createdat" => descending
                        ? responseList.OrderByDescending(x => x.CreatedAt).ToList()
                        : responseList.OrderBy(x => x.CreatedAt).ToList(),
                    "updatedat" => descending
                        ? responseList.OrderByDescending(x => x.UpdatedAt).ToList()
                        : responseList.OrderBy(x => x.UpdatedAt).ToList(),
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

            return new PagedResult<PharmacologicalCategoryResponse>
            {
                Items = responseList,
                TotalCount = totalCount
            };
        }
    }
}
