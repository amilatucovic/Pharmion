using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;

namespace Pharmion.Services.Services
{
    public class PatientService : BaseService<PatientResponse, PatientSearchObject, Patient>, IPatientService
    {
        public PatientService(PharmionDbContext context, IMapper mapper) : base(context, mapper)
        {
        }

        public override async Task<PagedResult<PatientResponse>> GetAsync(PatientSearchObject search)
        {
            var query = _context.Patients
                .Include(p => p.City)
                .AsQueryable();

            if (!string.IsNullOrEmpty(search.Name))
                query = query.Where(p =>
                    (p.FirstName + " " + p.LastName).Contains(search.Name) ||
                    p.Username.Contains(search.Name));

            if (!string.IsNullOrEmpty(search.JMBG))
                query = query.Where(p => p.JMBG.Contains(search.JMBG));

            if (search.IsInsured.HasValue)
                query = query.Where(p => p.IsInsured == search.IsInsured.Value);

            if (search.CityId.HasValue)
                query = query.Where(p => p.CityId == search.CityId.Value);

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync();

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
                query = query.Skip(search.Page.Value * search.PageSize.Value)
                             .Take(search.PageSize.Value);

            var patients = await query.OrderBy(p => p.LastName).ToListAsync();

            return new PagedResult<PatientResponse>
            {
                Items = patients.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<PatientResponse?> GetByIdAsync(int id)
        {
            var patient = await _context.Patients
                                     .Include(p => p.City)
                                     .Include(p => p.ChronicDiseases)
                                     .ThenInclude(cd => cd.ChronicDisease)
                                     .FirstOrDefaultAsync(p => p.Id == id);



            return patient == null ? null : MapToResponse(patient);
        }

        private PatientResponse MapToResponse(Patient p) => new PatientResponse
        {
            Id = p.Id,
            FirstName = p.FirstName,
            LastName = p.LastName,
            Username = p.Username,
            Email = p.Email,
            Gender = p.Gender,
            DateOfBirth = p.DateOfBirth,
            JMBG = p.JMBG,
            InsuranceNumber = p.InsuranceNumber,
            Address = p.Address,
            CityId = p.CityId,
            CityName = p.City?.Name ?? string.Empty,
            PhoneNumber = p.PhoneNumber,
            EmergencyContact = p.EmergencyContact,
            IsInsured = p.IsInsured,
            IsActive = p.IsActive,
            CreatedAt = p.CreatedAt,
            ChronicDiseases = p.ChronicDiseases
                                       .Select(cd => cd.ChronicDisease?.Name ?? string.Empty)
                                       .Where(name => !string.IsNullOrEmpty(name))
                                       .ToList(),
        };
    }
}