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
    public class ChronicDiseaseService : BaseCRUDService<ChronicDiseaseResponse, ChronicDiseaseSearchObject, ChronicDisease, ChronicDiseaseUpsertRequest, ChronicDiseaseUpsertRequest>, IChronicDiseaseService
    {
        private readonly PharmionDbContext _context;
        public ChronicDiseaseService(PharmionDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<ChronicDisease> ApplyFilter(IQueryable<ChronicDisease> query, ChronicDiseaseSearchObject search)
        {
            if (!string.IsNullOrEmpty(search.Code))
            {
                query = query.Where(cd => cd.Code.Contains(search.Code));
            }
            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(cd => cd.Name.Contains(search.Name));
            }
            if (search.IsActive.HasValue)
            {
                query = query.Where(cd => cd.IsActive == search.IsActive.Value);
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(cd => cd.Code.Contains(search.FTS)
                                       || cd.Name.Contains(search.FTS)
                                       || cd.Description.Contains(search.FTS));
            }

            return query;
        }

        protected override async Task BeforeInsert(ChronicDisease entity, ChronicDiseaseUpsertRequest request)
        {
            if (await _context.ChronicDiseases.AnyAsync(cd => cd.Code == request.Code))
                throw new UserException("Chronic disease with this code already exists.");

            if (await _context.ChronicDiseases.AnyAsync(cd => cd.Name == request.Name))
                throw new UserException("Chronic disease with this name already exists.");

            entity.CreatedAt = DateTime.UtcNow;
        }

        protected override async Task BeforeUpdate(ChronicDisease entity, ChronicDiseaseUpsertRequest request)
        { 
            if (await _context.ChronicDiseases.AnyAsync(cd => cd.Code == request.Code && cd.Id != entity.Id))
                throw new UserException("Chronic disease with this code already exists.");

            if (await _context.ChronicDiseases.AnyAsync(cd => cd.Name == request.Name && cd.Id != entity.Id))
                throw new UserException("Chronic disease with this name already exists.");

            entity.UpdatedAt = DateTime.UtcNow;
        }

        protected override void MapUpdateToEntity(ChronicDisease entity, ChronicDiseaseUpsertRequest request)
        {
            base.MapUpdateToEntity(entity, request);
        }

        protected override async Task BeforeDelete(ChronicDisease entity)
        {
            var hasPatients = await _context.PatientChronicDiseases.AnyAsync(pcd => pcd.ChronicDiseaseId == entity.Id);

            if (hasPatients)
                throw new UserException("Cannot delete chronic disease: it is assigned to one or more patients.");
        }

        public override async Task<PagedResult<ChronicDiseaseResponse>> GetAsync(ChronicDiseaseSearchObject search)
        {
            var baseQuery = _context.Set<ChronicDisease>().AsQueryable();

            baseQuery = ApplyFilter(baseQuery, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await baseQuery.CountAsync();
            }

            var entities = await baseQuery.ToListAsync();

            var responseList = entities.Select(cd => new ChronicDiseaseResponse
            {
                Id = cd.Id,
                Code = cd.Code,
                Name = cd.Name,
                Description = cd.Description,
                IsActive = cd.IsActive,
                CreatedAt = cd.CreatedAt,
                UpdatedAt = cd.UpdatedAt
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

            return new PagedResult<ChronicDiseaseResponse>
            {
                Items = responseList,
                TotalCount = totalCount
            };
        }
    }
}

