using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Model.Exceptions;
using Pharmion.Model.Messages;
using Pharmion.Model.Requests;
using Pharmion.Model.Responses;
using Pharmion.Model.SearchObjects;
using Pharmion.Services.Database;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Interfaces;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;
using Pharmion.Services.StateMachines.ReservationStateMachine;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Pharmion.Services.Services
{
    public class ReservationService : BaseCRUDService<ReservationResponse, ReservationSearchObject, Reservation, ReservationInsertRequest, ReservationUpdateRequest>, IReservationService
    {
        private readonly PharmionDbContext _context;
        private readonly IServiceProvider _serviceProvider;
        private readonly IRabbitMQPublisher _publisher;

        public ReservationService(
            PharmionDbContext context,
            IMapper mapper,
            IServiceProvider serviceProvider,
            IRabbitMQPublisher publisher) : base(context, mapper)
        {
            _context = context;
            _serviceProvider = serviceProvider;
            _publisher = publisher;
        }

        public override async Task<PagedResult<ReservationResponse>> GetAsync(ReservationSearchObject search)
        {
            var query = _context.Reservations
                .Include(r => r.Patient)
                .Include(r => r.Pharmacy)
                .Include(r => r.Items)
                    .ThenInclude(i => i.Product)
                .AsQueryable();

            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
                totalCount = await query.CountAsync();

            if (!search.RetrieveAll && search.Page.HasValue && search.PageSize.HasValue)
                query = query.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);

            var reservations = await query
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return new PagedResult<ReservationResponse>
            {
                Items = reservations.Select(MapReservationToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        public override async Task<ReservationResponse> GetByIdAsync(int id)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Patient)
                .Include(r => r.Pharmacy)
                .Include(r => r.Items)
                    .ThenInclude(i => i.Product)
                .FirstOrDefaultAsync(r => r.Id == id)
                ?? throw new UserException("Reservation not found");

            return MapReservationToResponse(reservation);
        }

        public override async Task<ReservationResponse> CreateAsync(ReservationInsertRequest request)
        {
            var initialState = _serviceProvider.GetService(typeof(InitialReservationState)) as InitialReservationState;
            if (initialState == null)
                throw new Exception("InitialReservationState not registered in DI");

            var created = await initialState.CreateAsync(request);

            var full = await _context.Reservations
                .Include(r => r.Patient)
                .Include(r => r.Pharmacy)
                .Include(r => r.Items)
                .FirstOrDefaultAsync(r => r.Id == created.Id)
                ?? throw new UserException("Greška pri kreiranju rezervacije");

            return MapReservationToResponse(full);
        }

        public override async Task<ReservationResponse> UpdateAsync(int id, ReservationUpdateRequest request)
        {
            var reservation = await _context.Reservations.FindAsync(id);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            await currentState.UpdateAsync(id, request);

            return await ReloadAndMapAsync(reservation.Id);

        }


        public async Task<ReservationResponse> SubmitAsync(int reservationId, int patientId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            await currentState.SubmitAsync(reservationId, patientId);

            var result = await ReloadAndMapAsync(reservationId);

            try
            {
                await _publisher.PublishAsync(new ReservationSubmittedMessage
                {
                    ReservationId = result.Id,
                    PatientEmail = result.PatientEmail,
                    PatientName = result.PatientName,
                    PharmacyName = result.PharmacyName,
                    CreatedAt = result.CreatedAt
                }, "reservation.submitted");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"RabbitMQ publish failed: {ex.Message}");
            }

            return result;

        }

        public async Task<ReservationResponse> ApproveAsync(int reservationId, int pharmacistId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            await currentState.ApproveAsync(reservationId, pharmacistId);

            return await ReloadAndMapAsync(reservationId);
        }

        public async Task<ReservationResponse> RejectAsync(int reservationId, int pharmacistId, string reason)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            await currentState.RejectAsync(reservationId, pharmacistId, reason);

            var result = await ReloadAndMapAsync(reservationId);

            try  
            {
                await _publisher.PublishAsync(new ReservationRejectedMessage
                {
                    ReservationId = result.Id,
                    PatientEmail = result.PatientEmail,
                    PatientName = result.PatientName,
                    PharmacyName = result.PharmacyName,
                    Reason = reason
                }, "reservation.rejected");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"RabbitMQ publish failed: {ex.Message}");
            }

            return result;
        }

        public async Task<ReservationResponse> MarkAsReadyAsync(int reservationId, int pharmacistId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            await currentState.MarkAsReadyAsync(reservationId, pharmacistId);

            var result = await ReloadAndMapAsync(reservationId);

            try
            {
                await _publisher.PublishAsync(new ReservationReadyMessage
                {
                    ReservationId = result.Id,
                    PatientEmail = result.PatientEmail,
                    PatientName = result.PatientName,
                    PharmacyName = result.PharmacyName,
                    PickupDeadline = result.PickupDeadline
                }, "reservation.ready");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"RabbitMQ publish failed: {ex.Message}");
            }
  
            return result;

        }

        public async Task<ReservationResponse> MarkAsPickedUpAsync(int reservationId, int pharmacistId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            await currentState.MarkAsPickedUpAsync(reservationId, pharmacistId);

            return await ReloadAndMapAsync(reservationId);

        }

        public async Task<ReservationResponse> CancelAsync(int reservationId, int userId, string reason)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var currentState = GetCurrentState(reservation.ReservationState);
            await currentState.CancelAsync(reservationId, userId, reason);

            return await ReloadAndMapAsync(reservationId);

        }


        public async Task<List<string>> GetAllowedActionsAsync(int reservationId)
        {
            var reservation = await _context.Reservations.FindAsync(reservationId);
            if (reservation == null)
                throw new UserException("Reservation not found");

            var allowedActions = new List<string>();

            switch (reservation.ReservationState)
            {
                case nameof(DraftReservationState):
                    allowedActions.AddRange(new[] { "Submit", "Update", "Cancel" });
                    break;

                case nameof(SubmittedReservationState):
                    allowedActions.AddRange(new[] { "Approve", "Reject", "Cancel" });
                    break;

                case nameof(ApprovedReservationState):
                    allowedActions.AddRange(new[] { "MarkAsReady", "Cancel" });
                    break;

                case nameof(ReadyForPickupReservationState):
                    allowedActions.AddRange(new[] { "MarkAsPickedUp", "Cancel" });
                    break;

                case nameof(PickedUpReservationState):
                case nameof(CancelledReservationState):
                case nameof(RejectedReservationState):
                    break;
            }

            return allowedActions;
        }

        public async Task<List<ReservationResponse>> GetReservationsByPatientAsync(int patientId)
        {
            var reservations = await _context.Reservations
                .Include(r => r.Items)
                    .ThenInclude(ri => ri.Product)
                .Include(r => r.Pharmacy)
                .Include(r => r.Patient)
                .Where(r => r.PatientId == patientId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return reservations.Select(MapReservationToResponse).ToList();

        }

        public async Task<List<ReservationResponse>> GetReservationsByPharmacyAsync(int pharmacyId)
        {
            var reservations = await _context.Reservations
                .Include(r => r.Items)
                    .ThenInclude(ri => ri.Product)
                .Include(r => r.Patient)
                .Include(r => r.Pharmacy)
                .Where(r => r.PharmacyId == pharmacyId)
                .OrderByDescending(r => r.CreatedAt)
                .ToListAsync();

            return reservations.Select(MapReservationToResponse).ToList();
        }

        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            if (search.PatientId.HasValue)
            {
                query = query.Where(r => r.PatientId == search.PatientId.Value);
            }

            if (search.PharmacyId.HasValue)
            {
                query = query.Where(r => r.PharmacyId == search.PharmacyId.Value);
            }

            if (!string.IsNullOrEmpty(search.ReservationState))
            {
                query = query.Where(r => r.ReservationState == search.ReservationState);
            }

            if (search.CreatedFrom.HasValue)
            {
                query = query.Where(r => r.CreatedAt >= search.CreatedFrom.Value);
            }

            if (search.CreatedTo.HasValue)
            {
                query = query.Where(r => r.CreatedAt <= search.CreatedTo.Value);
            }

            if (!string.IsNullOrEmpty(search.PatientName))
            {
                query = query.Where(r =>
                    (r.Patient.FirstName + " " + r.Patient.LastName)
                        .Contains(search.PatientName));
            }

            return query;
        }

        private BaseReservationState GetCurrentState(string stateName)
        {

            var baseState = _serviceProvider.GetService(typeof(DraftReservationState)) as BaseReservationState;
            if (baseState == null)
                throw new Exception("State machine not properly configured");

            return baseState.GetReservationState(stateName);
        }


        public async Task<List<ReservationItemResponse>> GetItemsAsync(int reservationId, int patientId)
        {
            var reservation = await _context.Reservations
                .FirstOrDefaultAsync(r => r.Id == reservationId);

            if (reservation == null)
                throw new UserException("Rezervacija nije pronađena");

            if (reservation.PatientId != patientId)
                throw new UserException("Nemate pristup ovoj rezervaciji");

            var items = await _context.ReservationItems
                .Include(i => i.Product)
                .Where(i => i.ReservationId == reservationId)
                .ToListAsync();

            return items.Select(MapItemToResponse).ToList();
        }

        public async Task<ReservationItemResponse> AddItemAsync(
            int reservationId, int patientId, ReservationItemInsertRequest request)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Items)
                .FirstOrDefaultAsync(r => r.Id == reservationId)
                ?? throw new UserException("Rezervacija nije pronađena");

            if (reservation.PatientId != patientId)
                throw new UserException("Nemate pristup ovoj rezervaciji");

            if (reservation.ReservationState != nameof(DraftReservationState))
                throw new UserException("Stavke možete mijenjati samo dok je rezervacija u Draft stanju");

            var product = await _context.Products
                .Include(p => p.MedicationDetails)
                    .ThenInclude(md => md.MedicationCategory)
                .FirstOrDefaultAsync(p => p.Id == request.ProductId && p.IsActive)
                ?? throw new UserException("Produkt nije pronađen ili nije aktivan");

            if (product.IsPrescriptionRequired)
            {
                if (!request.PrescriptionItemId.HasValue)
                    throw new UserException($"Lijek '{product.Name}' zahtijeva recept");

                var prescriptionItem = await _context.PrescriptionItems
                    .Include(pi => pi.Prescription)
                    .FirstOrDefaultAsync(pi => pi.Id == request.PrescriptionItemId.Value)
                    ?? throw new UserException("Stavka recepta nije pronađena");

                if (prescriptionItem.Prescription!.PatientId != patientId)
                    throw new UserException("Recept ne pripada ovom pacijentu");

                if (prescriptionItem.Prescription.Status != PrescriptionStatus.Active)
                    throw new UserException("Recept nije aktivan");

                if (prescriptionItem.Prescription.ValidTo.HasValue
                    && prescriptionItem.Prescription.ValidTo.Value < DateTime.UtcNow)
                    throw new UserException("Recept je istekao");

                if (prescriptionItem.RepeatsUsed >= prescriptionItem.Repeats)
                    throw new UserException("Iskoristili ste sva ponavljanja za ovaj lijek");

                if (prescriptionItem.NextEligibleDispenseAt.HasValue
                    && prescriptionItem.NextEligibleDispenseAt.Value > DateTime.UtcNow)
                {
                    var daysLeft = (int)Math.Ceiling(
                        (prescriptionItem.NextEligibleDispenseAt.Value - DateTime.UtcNow).TotalDays);
                    throw new UserException(
                        $"Prerano za rezervaciju lijeka '{product.Name}'. " +
                        $"Sljedeće preuzimanje je za {daysLeft} dan(a) " +
                        $"({prescriptionItem.NextEligibleDispenseAt.Value:dd.MM.yyyy})");
                }

                if (prescriptionItem.ProductId != request.ProductId)
                    throw new UserException("Odabrani produkt ne odgovara stavci recepta");
            }

            var patient = await _context.Patients.FindAsync(patientId)
                       ?? throw new UserException("Pacijent nije pronađen");
            var (patientPart, insurancePart) = CalculateParticipation(product, patient.IsInsured);


            var existingItem = reservation.Items
                .FirstOrDefault(i => i.ProductId == request.ProductId);

            ReservationItem item;

            if (existingItem != null)
            {
                existingItem.Quantity += request.Quantity;
                existingItem.LineTotal = existingItem.Quantity * existingItem.UnitPrice;
                existingItem.PatientPart = existingItem.Quantity * patientPart;
                existingItem.InsurancePart = existingItem.Quantity * insurancePart;
                item = existingItem;
            }
            else
            {
                item = new ReservationItem
                {
                    ReservationId = reservationId,
                    ProductId = request.ProductId,
                    Quantity = request.Quantity,
                    UnitPrice = product.Price,
                    LineTotal = request.Quantity * product.Price,
                    PatientPart = request.Quantity * patientPart,
                    InsurancePart = request.Quantity * insurancePart,
                    PrescriptionItemId = request.PrescriptionItemId,
                };
                _context.ReservationItems.Add(item);
            }

            RecalculateTotals(reservation);
            await _context.SaveChangesAsync();

            // Reload sa produktom za response
            await _context.Entry(item).Reference(i => i.Product).LoadAsync();

            return MapItemToResponse(item);
        }

        public async Task<ReservationItemResponse> UpdateItemAsync(
            int reservationId, int itemId, int patientId, ReservationItemUpdateRequest request)
        {
            var item = await GetAndValidateItemAsync(reservationId, itemId, patientId);

            item.Quantity = request.Quantity;
            item.LineTotal = item.Quantity * item.UnitPrice;
            item.PatientPart = item.LineTotal;

            RecalculateTotals(item.Reservation!);
            await _context.SaveChangesAsync();

            return MapItemToResponse(item);
        }

        public async Task DeleteItemAsync(int reservationId, int itemId, int patientId)
        {
            var item = await GetAndValidateItemAsync(reservationId, itemId, patientId);

            _context.ReservationItems.Remove(item);
            RecalculateTotals(item.Reservation!);

            await _context.SaveChangesAsync();
        }

        public async Task<ReservationResponse> AddToReservationAsync(int patientId, AddToReservationRequest request)
        {
            // 1. Pronađi postojeću Draft rezervaciju ili kreiraj novu
            var reservation = await _context.Reservations
                .Include(r => r.Items)
                .FirstOrDefaultAsync(r =>
                    r.PatientId == patientId &&
                    r.PharmacyId == request.PharmacyId &&
                    r.ReservationState == nameof(DraftReservationState));

            if (reservation == null)
            {
                reservation = new Reservation
                {
                    PatientId = patientId,
                    PharmacyId = request.PharmacyId,
                    ReservationState = nameof(DraftReservationState),
                    CreatedAt = DateTime.UtcNow
                };
                _context.Reservations.Add(reservation);
                await _context.SaveChangesAsync();

                // Reload sa Items kolekcijom
                reservation = await _context.Reservations
                    .Include(r => r.Items)
                    .FirstAsync(r => r.Id == reservation.Id);
            }

            // 2. Validacija i dodavanje itema (ista logika kao AddItemAsync)
            var product = await _context.Products
                .Include(p => p.MedicationDetails)
                    .ThenInclude(md => md.MedicationCategory)
                .FirstOrDefaultAsync(p => p.Id == request.ProductId && p.IsActive)
                ?? throw new UserException("Produkt nije pronađen");

            if (product.IsPrescriptionRequired)
            {
                if (!request.PrescriptionItemId.HasValue)
                    throw new UserException($"Lijek '{product.Name}' zahtijeva recept");

                var prescriptionItem = await _context.PrescriptionItems
                    .Include(pi => pi.Prescription)
                    .FirstOrDefaultAsync(pi => pi.Id == request.PrescriptionItemId.Value)
                    ?? throw new UserException("Stavka recepta nije pronađena");

                // Validacije recepta...
                if (prescriptionItem.Prescription!.PatientId != patientId)
                    throw new UserException("Recept ne pripada ovom pacijentu");

                if (prescriptionItem.RepeatsUsed >= prescriptionItem.Repeats)
                    throw new UserException("Iskoristili ste sva ponavljanja za ovaj lijek");

                // Early dispense provjera
                if (prescriptionItem.NextEligibleDispenseAt.HasValue &&
                    prescriptionItem.NextEligibleDispenseAt.Value > DateTime.UtcNow)
                {
                    if (string.IsNullOrEmpty(request.EarlyDispenseReason))
                    {
                        var daysLeft = (int)Math.Ceiling(
                            (prescriptionItem.NextEligibleDispenseAt.Value - DateTime.UtcNow).TotalDays);

                        throw new EarlyDispenseRequiredException(
                            $"Prerano za rezervaciju. Sljedeće preuzimanje je za {daysLeft} dan(a).",
                            prescriptionItem.NextEligibleDispenseAt.Value,
                            daysLeft);
                    }

                    if (!request.EarlyDispenseReasonType.HasValue)
                        throw new UserException("Morate odabrati razlog prijevremene rezervacije");

                    var earlyDispenseRecord = new EarlyDispenseException
                    {
                        PrescriptionItemId = prescriptionItem.Id,
                        ReservationId = reservation.Id,
                        RequestedAt = DateTime.UtcNow,
                        Status = ExceptionStatus.Pending,
                        ReasonType = request.EarlyDispenseReasonType.Value,
                        OtherReason = request.EarlyDispenseReason,
                        Note = null
                    };
                }
            }

            var patient = await _context.Patients.FindAsync(patientId)
                ?? throw new UserException("Pacijent nije pronađen");

            var (patientPart, insurancePart) = CalculateParticipation(product, patient.IsInsured);

            var existingItem = reservation.Items.FirstOrDefault(i => i.ProductId == request.ProductId);

            if (existingItem != null)
            {
                existingItem.Quantity += request.Quantity;
                existingItem.LineTotal = existingItem.Quantity * existingItem.UnitPrice;
                existingItem.PatientPart = existingItem.Quantity * patientPart;
                existingItem.InsurancePart = existingItem.Quantity * insurancePart;
            }
            else
            {
                _context.ReservationItems.Add(new ReservationItem
                {
                    ReservationId = reservation.Id,
                    ProductId = request.ProductId,
                    Quantity = request.Quantity,
                    UnitPrice = product.Price,
                    LineTotal = request.Quantity * product.Price,
                    PatientPart = request.Quantity * patientPart,
                    InsurancePart = request.Quantity * insurancePart,
                    PrescriptionItemId = request.PrescriptionItemId,
                    IsSubstitutionAllowed = request.IsSubstitutionAllowed
                });
            }

            RecalculateTotals(reservation);
            await _context.SaveChangesAsync();

            return await ReloadAndMapAsync(reservation.Id);
        }

        // Helperi

        private async Task<ReservationResponse> ReloadAndMapAsync(int reservationId)
        {
            var full = await _context.Reservations
                .Include(r => r.Patient)
                .Include(r => r.Pharmacy)
                .Include(r => r.Items).ThenInclude(i => i.Product)
                .FirstOrDefaultAsync(r => r.Id == reservationId)
                ?? throw new UserException("Reservation not found");

            return MapReservationToResponse(full);
        }


        private async Task<ReservationItem> GetAndValidateItemAsync(
            int reservationId, int itemId, int patientId)
        {
            var item = await _context.ReservationItems
                .Include(i => i.Reservation)
                .Include(i => i.Product)
                .FirstOrDefaultAsync(i => i.Id == itemId && i.ReservationId == reservationId)
                ?? throw new UserException("Stavka nije pronađena");

            if (item.Reservation!.PatientId != patientId)
                throw new UserException("Nemate pristup ovoj stavci");

            if (item.Reservation.ReservationState != nameof(DraftReservationState))
                throw new UserException("Stavke možete mijenjati samo dok je rezervacija u Draft stanju");

            return item;
        }

        private (decimal patientPart, decimal insurancePart) CalculateParticipation(Product product, bool isInsured)
        {
            // Neosigurani pacijent plaća sve bez obzira na kategoriju
            if (!isInsured)
                return (product.Price, 0);

            // Suplementi ili produkti bez MedicationDetails → pacijent plaća sve
            var category = product.MedicationDetails?.MedicationCategory;
            if (category == null)
                return (product.Price, 0);

            // Kategorija A → FlatFee (1 KM), osiguranje ostatak
            if (category.FlatFee.HasValue)
                return (category.FlatFee.Value, product.Price - category.FlatFee.Value);

            // Kategorija B ili C → prema postocima iz baze
            var patientPart = product.Price * (category.PatientPaymentPercentage / 100);
            var insurancePart = product.Price * (category.InsurancePaymentPercentage / 100);

            return (patientPart, insurancePart);
        }

        private void RecalculateTotals(Reservation reservation)
        {
            reservation.TotalAmount = reservation.Items.Sum(i => i.LineTotal);
            reservation.PatientPaysAmount = reservation.Items.Sum(i => i.PatientPart);
            reservation.InsurancePaysAmount = reservation.Items.Sum(i => i.InsurancePart);
            reservation.UpdatedAt = DateTime.UtcNow;
        }

        private ReservationItemResponse MapItemToResponse(ReservationItem item)
        {
            return new ReservationItemResponse
            {
                Id = item.Id,
                ReservationId = item.ReservationId,
                ProductId = item.ProductId,
                ProductName = item.Product?.Name ?? string.Empty,
                ProductType = item.Product?.Type.ToString() ?? string.Empty,
                Quantity = item.Quantity,
                UnitPrice = item.UnitPrice,
                LineTotal = item.LineTotal,
                PatientPart = item.PatientPart,
                InsurancePart = item.InsurancePart,
                PrescriptionItemId = item.PrescriptionItemId,
                IsSubstitutionAllowed = item.IsSubstitutionAllowed,
                RequiresPrescription = item.Product?.IsPrescriptionRequired ?? false
            };
        }

        private ReservationResponse MapReservationToResponse(Reservation r)
        {
            return new ReservationResponse
            {
                Id = r.Id,
                PatientId = r.PatientId,
                PatientName = r.Patient != null ? $"{r.Patient.FirstName} {r.Patient.LastName}" : string.Empty,
                PharmacyId = r.PharmacyId,
                PharmacyName = r.Pharmacy?.Name ?? string.Empty,
                ReservationState = r.ReservationState,
                ReservationStateDisplay = r.ReservationState.Replace("ReservationState", string.Empty),
                PatientEmail = r.Patient?.Email ?? string.Empty, 
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt,
                SubmittedAt = r.SubmittedAt,
                ApprovedAt = r.ApprovedAt,
                ReadyForPickupAt = r.ReadyForPickupAt,
                PickedUpAt = r.PickedUpAt,
                TotalAmount = r.TotalAmount,
                PatientPaysAmount = r.PatientPaysAmount,
                InsurancePaysAmount = r.InsurancePaysAmount,
                PickupDeadline = r.PickupDeadline,
                Items = r.Items?.Select(MapItemToResponse).ToList() ?? new List<ReservationItemResponse>()
            };
        }
    }
}