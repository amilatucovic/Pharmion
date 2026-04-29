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
    public class PrescriptionService
        : BaseCRUDService<PrescriptionResponse, PrescriptionSearchObject,
                          Prescription, PrescriptionUpsertRequest, PrescriptionUpsertRequest>,
          IPrescriptionService
    {
        public PrescriptionService(PharmionDbContext context, IMapper mapper)
            : base(context, mapper) { }

        public override async Task<PagedResult<PrescriptionResponse>> GetAsync(PrescriptionSearchObject search)
        {
            var query = _context.Prescriptions
                .Include(p => p.Patient)
                .Include(p => p.CreatedByPharmacist)
                .Include(p => p.Items)
                    .ThenInclude(i => i.Product)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync();

            query = query.OrderByDescending(p => p.IssuedAt);

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
                query = query.Skip(search.Page.Value * search.PageSize.Value)
                             .Take(search.PageSize.Value);

            var items = await query.ToListAsync();

            return new PagedResult<PrescriptionResponse>
            {
                Items = items.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<PrescriptionResponse?> GetByIdAsync(int id)
        {
            var p = await _context.Prescriptions
                .Include(p => p.Patient)
                .Include(p => p.CreatedByPharmacist)
                .Include(p => p.Items)
                    .ThenInclude(i => i.Product)
                .FirstOrDefaultAsync(p => p.Id == id);

            return p == null ? throw new NotFoundException($"Prescription with ID {id} does not exist") : MapToResponse(p);
        }

        protected override IQueryable<Prescription> ApplyFilter(
            IQueryable<Prescription> query, PrescriptionSearchObject search)
        {
            if (search.PatientId.HasValue)
                query = query.Where(p => p.PatientId == search.PatientId.Value);

            if (search.CreatedByPharmacistId.HasValue)
                query = query.Where(p => p.CreatedByPharmacistId == search.CreatedByPharmacistId.Value);

            if (!string.IsNullOrEmpty(search.DoctorName))
                query = query.Where(p => p.DoctorName.Contains(search.DoctorName));

            if (search.Status.HasValue)
                query = query.Where(p => p.Status == search.Status.Value);

            if (search.IssuedFrom.HasValue)
                query = query.Where(p => p.IssuedAt >= search.IssuedFrom.Value);

            if (search.IssuedTo.HasValue)
                query = query.Where(p => p.IssuedAt <= search.IssuedTo.Value);

            return query;
        }

        protected override async Task BeforeInsert(Prescription entity, PrescriptionUpsertRequest request)
        {
            var patient = await _context.Patients.FindAsync(request.PatientId)
                ?? throw new UserException("Pacijent nije pronađen.");

           
            entity.IssuedAt = DateTime.UtcNow;
            entity.Status = PrescriptionStatus.Active;

            entity.Items = request.Items.Select(i => new PrescriptionItem
            {
                ProductId = i.ProductId,
                Dosage = i.Dosage,
                QuantityPerPeriod = i.QuantityPerPeriod,
                PeriodDays = i.PeriodDays,
                Repeats = i.Repeats,
                RepeatsUsed = 0,
                TherapyType = i.TherapyType,
                NextEligibleDispenseAt = DateTime.UtcNow 
            }).ToList();
        }

        protected override async Task BeforeUpdate(Prescription entity, PrescriptionUpsertRequest request)
        {
            if (entity.Status != PrescriptionStatus.Active)
                throw new UserException("Nije moguće izmijeniti recept koji nije aktivan.");

            
            var oldItems = _context.PrescriptionItems.Where(i => i.PrescriptionId == entity.Id);
            _context.PrescriptionItems.RemoveRange(oldItems);

            entity.Items = request.Items.Select(i => new PrescriptionItem
            {
                ProductId = i.ProductId,
                Dosage = i.Dosage,
                QuantityPerPeriod = i.QuantityPerPeriod,
                PeriodDays = i.PeriodDays,
                Repeats = i.Repeats,
                RepeatsUsed = 0,
                TherapyType = i.TherapyType,
                NextEligibleDispenseAt = DateTime.UtcNow
            }).ToList();
        }

        protected override void MapUpdateToEntity(Prescription entity, PrescriptionUpsertRequest request)
        {
            entity.PatientId = request.PatientId;
            entity.DoctorName = request.DoctorName;
            entity.Facility = request.Facility;
            entity.ValidFrom = request.ValidFrom;
            entity.ValidTo = request.ValidTo;
            entity.Notes = request.Notes;
        }

        public async Task<PrescriptionResponse> CreateAsync(PrescriptionUpsertRequest request, int pharmacistId)
        {
            var patient = await _context.Patients.FindAsync(request.PatientId)
                ?? throw new UserException("Pacijent nije pronađen.");

            var prescription = new Prescription
            {
                PatientId = request.PatientId,
                CreatedByPharmacistId = pharmacistId, 
                DoctorName = request.DoctorName,
                Facility = request.Facility,
                IssuedAt = DateTime.UtcNow,
                ValidFrom = request.ValidFrom,
                ValidTo = request.ValidTo,
                Notes = request.Notes,
                Status = PrescriptionStatus.Active,
                Items = request.Items.Select(i => new PrescriptionItem
                {
                    ProductId = i.ProductId,
                    Dosage = i.Dosage,
                    QuantityPerPeriod = i.QuantityPerPeriod,
                    PeriodDays = i.PeriodDays,
                    Repeats = i.Repeats,
                    RepeatsUsed = 0,
                    TherapyType = i.TherapyType,
                    NextEligibleDispenseAt = DateTime.UtcNow
                }).ToList()
            };

            _context.Prescriptions.Add(prescription);
            await _context.SaveChangesAsync();

            return await GetByIdAsync(prescription.Id)
                ?? throw new UserException("Greška pri kreiranju recepta.");
        }

        public async Task CancelAsync(int id)
        {
            var prescription = await _context.Prescriptions.FindAsync(id)
                ?? throw new UserException("Recept nije pronađen.");

            if (prescription.Status == PrescriptionStatus.Cancelled)
                throw new UserException("Recept je već otkazan.");

            prescription.Status = PrescriptionStatus.Cancelled;
            await _context.SaveChangesAsync();
        }

        private PrescriptionResponse MapToResponse(Prescription p) => new()
        {
            Id = p.Id,
            PatientId = p.PatientId,
            PatientName = p.Patient != null
                ? $"{p.Patient.FirstName} {p.Patient.LastName}"
                : string.Empty,
            CreatedByPharmacistId = p.CreatedByPharmacistId,
            PharmacistName = p.CreatedByPharmacist != null
                ? $"{p.CreatedByPharmacist.FirstName} {p.CreatedByPharmacist.LastName}"
                : string.Empty,
            DoctorName = p.DoctorName,
            Facility = p.Facility,
            IssuedAt = p.IssuedAt,
            ValidFrom = p.ValidFrom,
            ValidTo = p.ValidTo,
            Status = p.Status,
            StatusDisplay = p.Status.ToString(),
            Notes = p.Notes,
            Items = p.Items.Select(i => new PrescriptionItemResponse
            {
                Id = i.Id,
                PrescriptionId = i.PrescriptionId,
                ProductId = i.ProductId,
                ProductName = i.Product?.Name ?? string.Empty,
                Dosage = i.Dosage,
                QuantityPerPeriod = i.QuantityPerPeriod,
                PeriodDays = i.PeriodDays,
                Repeats = i.Repeats,
                RepeatsUsed = i.RepeatsUsed,
                TherapyType = i.TherapyType,
                TherapyTypeDisplay = i.TherapyType.ToString(),
                LastDispensedAt = i.LastDispensedAt,
                NextEligibleDispenseAt = i.NextEligibleDispenseAt
            }).ToList()
        };
    }
}