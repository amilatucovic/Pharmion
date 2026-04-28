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
    public class MedicationCategoryService : BaseCRUDService<MedicationCategoryResponse, MedicationCategorySearchObject, MedicationCategory, MedicationCategoryInsertRequest, MedicationCategoryUpdateRequest>, IMedicationCategoryService
    {
        private readonly PharmionDbContext _context;
        public MedicationCategoryService(PharmionDbContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
        }

        protected override IQueryable<MedicationCategory> ApplyFilter(IQueryable<MedicationCategory> query, MedicationCategorySearchObject search)
        {
            if (search.Code.HasValue)
            {
                query = query.Where(mc => mc.Code == search.Code.Value);
            }

            if (!string.IsNullOrEmpty(search.Name))
            {
                query = query.Where(mc => mc.Name.Contains(search.Name));
            }

            if (!string.IsNullOrEmpty(search.FTS))
            {
                query = query.Where(mc => mc.Name.Contains(search.FTS)
                                       || mc.Description.Contains(search.FTS));
            }

            return query;
        }

        private async Task ValidateNameUnique(string name, int? id = null)
        {
            if (await _context.MedicationCategories.AnyAsync(mc => mc.Name == name && mc.Id != id))
                throw new UserException("Medication category with this name already exists.");
        }

        private void ValidatePaymentPercentages(decimal patientPercentage, decimal insurancePercentage, decimal? flatFee)
        {
            if (flatFee.HasValue)
            {
                if (patientPercentage != 0 || insurancePercentage != 0)
                    throw new UserException("FlatFee category should not have patient or insurance percentages.");
            }
            else
            {
                if (patientPercentage + insurancePercentage != 100)
                    throw new UserException("Patient and Insurance percentages must sum to 100 if FlatFee is not set.");
            }
        }



        protected override async Task BeforeInsert(MedicationCategory entity, MedicationCategoryInsertRequest request)
        {
            if (await _context.MedicationCategories.AnyAsync(mc => mc.Code == request.Code))
                throw new UserException("Medication category with this code already exists.");

            await ValidateNameUnique(request.Name);

            ValidatePaymentPercentages(request.PatientPaymentPercentage, request.InsurancePaymentPercentage, request.FlatFee);

            entity.CreatedAt = DateTime.UtcNow;
        }


        protected override async Task BeforeUpdate(MedicationCategory entity, MedicationCategoryUpdateRequest request)
        {
            await ValidateNameUnique(request.Name, entity.Id);

            ValidatePaymentPercentages(request.PatientPaymentPercentage, request.InsurancePaymentPercentage, request.FlatFee);

            entity.UpdatedAt = DateTime.UtcNow;
        }


        protected override void MapUpdateToEntity(MedicationCategory entity, MedicationCategoryUpdateRequest request)
        {
            entity.Name = request.Name;
            entity.Description = request.Description;
            entity.PatientPaymentPercentage = request.PatientPaymentPercentage;
            entity.InsurancePaymentPercentage = request.InsurancePaymentPercentage;
            entity.FlatFee = request.FlatFee;
        }

        protected override async Task BeforeDelete(MedicationCategory entity)
        { 
            var hasMedications = await _context.MedicationDetails.AnyAsync(m => m.MedicationCategoryId == entity.Id);

            if (hasMedications)
                throw new UserException("Cannot delete medication category: it is assigned to one or more medications.");
        }

        public override async Task<PagedResult<MedicationCategoryResponse>> GetAsync(MedicationCategorySearchObject search)
        {
            var baseQuery = _context.Set<MedicationCategory>().AsQueryable();

            baseQuery = ApplyFilter(baseQuery, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await baseQuery.CountAsync();
            }

            var entities = await baseQuery.ToListAsync();

            var responseList = entities.Select(mc => new MedicationCategoryResponse
            {
                Id = mc.Id,
                Code = mc.Code,
                CodeName = mc.Code.ToString(),
                Name = mc.Name,
                Description = mc.Description,
                PatientPaymentPercentage = mc.PatientPaymentPercentage,
                InsurancePaymentPercentage = mc.InsurancePaymentPercentage,
                FlatFee = mc.FlatFee,
                CreatedAt = mc.CreatedAt,
                UpdatedAt = mc.UpdatedAt
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

            return new PagedResult<MedicationCategoryResponse>
            {
                Items = responseList,
                TotalCount = totalCount
            };
        }

    }
}
