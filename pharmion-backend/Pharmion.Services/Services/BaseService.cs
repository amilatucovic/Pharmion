using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Extensions;
using Pharmion.Services.Interfaces;

namespace Pharmion.Services.Services
{
    public abstract class BaseService<T, TSearch, TEntity> : IService<T, TSearch> where T : class where TSearch : BaseSearchObject where TEntity : class
    {
        protected readonly PharmionDbContext _context;
        protected readonly IMapper _mapper;
        private const int MaxPageSize = 100;

        public BaseService(PharmionDbContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<PagedResult<T>> GetAsync(TSearch search)
        {
            var query = _context.Set<TEntity>().AsQueryable();
            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.PageSize.HasValue && search.PageSize.Value > MaxPageSize)
                    search.PageSize = MaxPageSize;

                if (search.Page.HasValue && search.PageSize.HasValue)
                    query = query.Skip(search.Page.Value * search.PageSize.Value)
                                 .Take(search.PageSize.Value);
                else if (search.PageSize.HasValue)
                    query = query.Take(search.PageSize.Value);
            }
            else
            {
                query = query.Take(MaxPageSize);
            }

            if (!string.IsNullOrWhiteSpace(search.OrderBy))
            {
                if (search.OrderBy.StartsWith("-"))
                {
                    query = query.OrderByDescendingDynamic(search.OrderBy[1..]);
                }
                else
                {
                    query = query.OrderByDynamic(search.OrderBy);
                }
            }


            var list = await query.ToListAsync();
            return new PagedResult<T>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        protected virtual IQueryable<TEntity> ApplyFilter(IQueryable<TEntity> query, TSearch search)
        {
            return query;
        }

        public virtual async Task<T?> GetByIdAsync(int id)
        {
            var entity = await _context.Set<TEntity>().FindAsync(id);
            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected virtual T MapToResponse(TEntity entity)
        {
            return _mapper.Map<T>(entity);
        }

    }
}
