using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using Pharmion.Services.Services.StateMachines.ReservationStateMachine;
using Pharmion.Services.StateMachines.ReservationStateMachine;

namespace Pharmion.Services.Database.Seed
{
    public class ReservationSeed : IEntitySeeder<Reservation>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.Reservations.AnyAsync())
                return;

            
            var pharmacyMostar = await context.Pharmacies.FirstOrDefaultAsync(p => p.Name == "LUPRIV PHARM 13");
            var pharmacySarajevo = await context.Pharmacies.FirstOrDefaultAsync(p => p.Name == "LUPRIV PHARM 15");

            if (pharmacyMostar == null || pharmacySarajevo == null) return;

            
            var pharmacist = await context.Pharmacists.FirstOrDefaultAsync(p => p.Username == "pharmacist");
            if (pharmacist == null) return;

            
            var testPatient = await context.Patients.FirstOrDefaultAsync(p => p.Username == "patient");

            
            var adnan = await context.Patients.FirstOrDefaultAsync(p => p.Username == "adnan.mahmutovic");
            var merima = await context.Patients.FirstOrDefaultAsync(p => p.Username == "merima.softic");
            var dzenan = await context.Patients.FirstOrDefaultAsync(p => p.Username == "dzenan.husic");
            var haris = await context.Patients.FirstOrDefaultAsync(p => p.Username == "haris.hodzic");
            var sajra = await context.Patients.FirstOrDefaultAsync(p => p.Username == "sajra.mulic");
            var kenan = await context.Patients.FirstOrDefaultAsync(p => p.Username == "kenan.zuljevic");

            
            var amlodipin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Amlodipin"));
            var metformin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Metformin"));
            var salbutamol = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Salbutamol"));
            var paracetamol = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Paracetamol"));
            var brufen = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Brufen"));
            var vitaminD = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Vitamin D3"));
            var magnesium = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Magnesium"));
            var bComplex = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("B-Complex"));
            var omega3 = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Omega 3"));
            var zinc = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Zinc"));
            var iron = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Iron"));

            if (vitaminD == null || magnesium == null || bComplex == null) return;

           
            var amlodipinPrescItem = await context.PrescriptionItems
                .Include(pi => pi.Prescription)
                .FirstOrDefaultAsync(pi => pi.Prescription.PatientId == testPatient.Id
                    && pi.Product.Name.Contains("Amlodipin"));

            var metforminPrescItem = await context.PrescriptionItems
                .Include(pi => pi.Prescription)
                .FirstOrDefaultAsync(pi => pi.Prescription.PatientId == testPatient.Id
                    && pi.Product.Name.Contains("Metformin"));

           

            var testPatientReservations = new[]
            {
               
                new Reservation
                {
                    PatientId = testPatient.Id,
                    PharmacyId = pharmacyMostar.Id,
                    ReservationState = nameof(PickedUpReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-45),
                    SubmittedAt = DateTime.UtcNow.AddDays(-45),
                    ApprovedAt = DateTime.UtcNow.AddDays(-44),
                    ReadyForPickupAt = DateTime.UtcNow.AddDays(-43),
                    PickedUpAt = DateTime.UtcNow.AddDays(-42),
                    ApprovedByPharmacistId = pharmacist.Id,
                    MarkedReadyByPharmacistId = pharmacist.Id,
                    MarkedPickedUpByPharmacistId = pharmacist.Id,
                    TotalAmount = amlodipin.Price,
                    PatientPaysAmount = Math.Round(amlodipin.Price * 0.4m, 2),
                    InsurancePaysAmount = Math.Round(amlodipin.Price * 0.6m, 2),
                    Items = new[]
                    {
                        new ReservationItem
                        {
                            ProductId = amlodipin.Id,
                            Quantity = 1,
                            UnitPrice = amlodipin.Price,
                            LineTotal = amlodipin.Price,
                            PatientPart = Math.Round(amlodipin.Price * 0.4m, 2),
                            InsurancePart = Math.Round(amlodipin.Price * 0.6m, 2),
                            PrescriptionItemId = amlodipinPrescItem?.Id
                        }
                    }
                },
                
                new Reservation
                {
                    PatientId = testPatient.Id,
                    PharmacyId = pharmacyMostar.Id,
                    ReservationState = nameof(PickedUpReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-30),
                    SubmittedAt = DateTime.UtcNow.AddDays(-30),
                    ApprovedAt = DateTime.UtcNow.AddDays(-29),
                    ReadyForPickupAt = DateTime.UtcNow.AddDays(-28),
                    PickedUpAt = DateTime.UtcNow.AddDays(-27),
                    ApprovedByPharmacistId = pharmacist.Id,
                    MarkedReadyByPharmacistId = pharmacist.Id,
                    MarkedPickedUpByPharmacistId = pharmacist.Id,
                    TotalAmount = vitaminD.Price + magnesium.Price,
                    PatientPaysAmount = vitaminD.Price + magnesium.Price,
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem
                        {
                            ProductId = vitaminD.Id,
                            Quantity = 1,
                            UnitPrice = vitaminD.Price,
                            LineTotal = vitaminD.Price,
                            PatientPart = vitaminD.Price,
                            InsurancePart = 0
                        },
                        new ReservationItem
                        {
                            ProductId = magnesium.Id,
                            Quantity = 1,
                            UnitPrice = magnesium.Price,
                            LineTotal = magnesium.Price,
                            PatientPart = magnesium.Price,
                            InsurancePart = 0
                        }
                    }
                },
                
                new Reservation
                {
                    PatientId = testPatient.Id,
                    PharmacyId = pharmacyMostar.Id,
                    ReservationState = nameof(SubmittedReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-5),
                    SubmittedAt = DateTime.UtcNow.AddDays(-5),
                    ApprovedAt = null,
                    ApprovedByPharmacistId = null,
                    TotalAmount = metformin.Price,
                    PatientPaysAmount = 1.00m,
                    InsurancePaysAmount = metformin.Price - 1.00m,
                    Items = new[]
                    {
                        new ReservationItem
                        {
                            ProductId = metformin.Id,
                            Quantity = 1,
                            UnitPrice = metformin.Price,
                            LineTotal = metformin.Price,
                            PatientPart = 1.00m,
                            InsurancePart = metformin.Price - 1.00m,
                            PrescriptionItemId = metforminPrescItem?.Id
                        }
                    }
                },
                
                new Reservation
                {
                    PatientId = testPatient.Id,
                    PharmacyId = pharmacyMostar.Id,
                    ReservationState = nameof(DraftReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-1),
                    TotalAmount = paracetamol.Price + brufen.Price,
                    PatientPaysAmount = paracetamol.Price + brufen.Price,
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem
                        {
                            ProductId = paracetamol.Id,
                            Quantity = 1,
                            UnitPrice = paracetamol.Price,
                            LineTotal = paracetamol.Price,
                            PatientPart = paracetamol.Price,
                            InsurancePart = 0
                        },
                        new ReservationItem
                        {
                            ProductId = brufen.Id,
                            Quantity = 1,
                            UnitPrice = brufen.Price,
                            LineTotal = brufen.Price,
                            PatientPart = brufen.Price,
                            InsurancePart = 0
                        }
                    }
                },
               
                new Reservation
                {
                    PatientId = testPatient.Id,
                    PharmacyId = pharmacyMostar.Id,
                    ReservationState = nameof(CancelledReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-15),
                    SubmittedAt = DateTime.UtcNow.AddDays(-15),
                    CancelledAt = DateTime.UtcNow.AddDays(-14),
                    CancelledByUserId = testPatient.Id,
                    CancellationReason = "Found medication elsewhere",
                    TotalAmount = brufen.Price * 2,
                    PatientPaysAmount = brufen.Price * 2,
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem
                        {
                            ProductId = brufen.Id,
                            Quantity = 2,
                            UnitPrice = brufen.Price,
                            LineTotal = brufen.Price * 2,
                            PatientPart = brufen.Price * 2,
                            InsurancePart = 0
                        }
                    }
                }
            };

            

            var otherPatientReservations = new[]
            {
                
                new Reservation
                {
                    PatientId = adnan.Id,
                    PharmacyId = pharmacySarajevo.Id,
                    ReservationState = nameof(PickedUpReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-20),
                    SubmittedAt = DateTime.UtcNow.AddDays(-20),
                    ApprovedAt = DateTime.UtcNow.AddDays(-19),
                    ReadyForPickupAt = DateTime.UtcNow.AddDays(-18),
                    PickedUpAt = DateTime.UtcNow.AddDays(-17),
                    ApprovedByPharmacistId = pharmacist.Id,
                    MarkedReadyByPharmacistId = pharmacist.Id,
                    MarkedPickedUpByPharmacistId = pharmacist.Id,
                    TotalAmount = vitaminD.Price + magnesium.Price + bComplex.Price,
                    PatientPaysAmount = vitaminD.Price + magnesium.Price + bComplex.Price,
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem { ProductId = vitaminD.Id, Quantity = 1, UnitPrice = vitaminD.Price, LineTotal = vitaminD.Price, PatientPart = vitaminD.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = magnesium.Id, Quantity = 1, UnitPrice = magnesium.Price, LineTotal = magnesium.Price, PatientPart = magnesium.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = bComplex.Id, Quantity = 1, UnitPrice = bComplex.Price, LineTotal = bComplex.Price, PatientPart = bComplex.Price, InsurancePart = 0 }
                    }
                },
                
                new Reservation
                {
                    PatientId = merima.Id,
                    PharmacyId = pharmacySarajevo.Id,
                    ReservationState = nameof(PickedUpReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-25),
                    SubmittedAt = DateTime.UtcNow.AddDays(-25),
                    ApprovedAt = DateTime.UtcNow.AddDays(-24),
                    ReadyForPickupAt = DateTime.UtcNow.AddDays(-23),
                    PickedUpAt = DateTime.UtcNow.AddDays(-22),
                    ApprovedByPharmacistId = pharmacist.Id,
                    MarkedReadyByPharmacistId = pharmacist.Id,
                    MarkedPickedUpByPharmacistId = pharmacist.Id,
                    TotalAmount = vitaminD.Price + (omega3?.Price ?? 0) + (iron?.Price ?? 0),
                    PatientPaysAmount = vitaminD.Price + (omega3?.Price ?? 0) + (iron?.Price ?? 0),
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem { ProductId = vitaminD.Id, Quantity = 1, UnitPrice = vitaminD.Price, LineTotal = vitaminD.Price, PatientPart = vitaminD.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = omega3?.Id ?? vitaminD.Id, Quantity = 1, UnitPrice = omega3?.Price ?? vitaminD.Price, LineTotal = omega3?.Price ?? vitaminD.Price, PatientPart = omega3?.Price ?? vitaminD.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = iron?.Id ?? magnesium.Id, Quantity = 1, UnitPrice = iron?.Price ?? magnesium.Price, LineTotal = iron?.Price ?? magnesium.Price, PatientPart = iron?.Price ?? magnesium.Price, InsurancePart = 0 }
                    }
                },
                
                new Reservation
                {
                    PatientId = dzenan.Id,
                    PharmacyId = pharmacyMostar.Id,
                    ReservationState = nameof(PickedUpReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-18),
                    SubmittedAt = DateTime.UtcNow.AddDays(-18),
                    ApprovedAt = DateTime.UtcNow.AddDays(-17),
                    ReadyForPickupAt = DateTime.UtcNow.AddDays(-16),
                    PickedUpAt = DateTime.UtcNow.AddDays(-15),
                    ApprovedByPharmacistId = pharmacist.Id,
                    MarkedReadyByPharmacistId = pharmacist.Id,
                    MarkedPickedUpByPharmacistId = pharmacist.Id,
                    TotalAmount = magnesium.Price + bComplex.Price + (omega3?.Price ?? 0),
                    PatientPaysAmount = magnesium.Price + bComplex.Price + (omega3?.Price ?? 0),
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem { ProductId = magnesium.Id, Quantity = 1, UnitPrice = magnesium.Price, LineTotal = magnesium.Price, PatientPart = magnesium.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = bComplex.Id, Quantity = 1, UnitPrice = bComplex.Price, LineTotal = bComplex.Price, PatientPart = bComplex.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = omega3?.Id ?? vitaminD.Id, Quantity = 1, UnitPrice = omega3?.Price ?? vitaminD.Price, LineTotal = omega3?.Price ?? vitaminD.Price, PatientPart = omega3?.Price ?? vitaminD.Price, InsurancePart = 0 }
                    }
                },
               
                new Reservation
                {
                    PatientId = haris.Id,
                    PharmacyId = pharmacySarajevo.Id,
                    ReservationState = nameof(PickedUpReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-12),
                    SubmittedAt = DateTime.UtcNow.AddDays(-12),
                    ApprovedAt = DateTime.UtcNow.AddDays(-11),
                    ReadyForPickupAt = DateTime.UtcNow.AddDays(-10),
                    PickedUpAt = DateTime.UtcNow.AddDays(-9),
                    ApprovedByPharmacistId = pharmacist.Id,
                    MarkedReadyByPharmacistId = pharmacist.Id,
                    MarkedPickedUpByPharmacistId = pharmacist.Id,
                    TotalAmount = vitaminD.Price + (zinc?.Price ?? 0) + bComplex.Price,
                    PatientPaysAmount = vitaminD.Price + (zinc?.Price ?? 0) + bComplex.Price,
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem { ProductId = vitaminD.Id, Quantity = 1, UnitPrice = vitaminD.Price, LineTotal = vitaminD.Price, PatientPart = vitaminD.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = zinc?.Id ?? magnesium.Id, Quantity = 1, UnitPrice = zinc?.Price ?? magnesium.Price, LineTotal = zinc?.Price ?? magnesium.Price, PatientPart = zinc?.Price ?? magnesium.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = bComplex.Id, Quantity = 1, UnitPrice = bComplex.Price, LineTotal = bComplex.Price, PatientPart = bComplex.Price, InsurancePart = 0 }
                    }
                },
               
                new Reservation
                {
                    PatientId = sajra.Id,
                    PharmacyId = pharmacySarajevo.Id,
                    ReservationState = nameof(PickedUpReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-8),
                    SubmittedAt = DateTime.UtcNow.AddDays(-8),
                    ApprovedAt = DateTime.UtcNow.AddDays(-7),
                    ReadyForPickupAt = DateTime.UtcNow.AddDays(-6),
                    PickedUpAt = DateTime.UtcNow.AddDays(-5),
                    ApprovedByPharmacistId = pharmacist.Id,
                    MarkedReadyByPharmacistId = pharmacist.Id,
                    MarkedPickedUpByPharmacistId = pharmacist.Id,
                    TotalAmount = magnesium.Price + (iron?.Price ?? 0) + vitaminD.Price,
                    PatientPaysAmount = magnesium.Price + (iron?.Price ?? 0) + vitaminD.Price,
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem { ProductId = magnesium.Id, Quantity = 1, UnitPrice = magnesium.Price, LineTotal = magnesium.Price, PatientPart = magnesium.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = iron?.Id ?? bComplex.Id, Quantity = 1, UnitPrice = iron?.Price ?? bComplex.Price, LineTotal = iron?.Price ?? bComplex.Price, PatientPart = iron?.Price ?? bComplex.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = vitaminD.Id, Quantity = 1, UnitPrice = vitaminD.Price, LineTotal = vitaminD.Price, PatientPart = vitaminD.Price, InsurancePart = 0 }
                    }
                },
                
                new Reservation
                {
                    PatientId = kenan.Id,
                    PharmacyId = pharmacySarajevo.Id,
                    ReservationState = nameof(PickedUpReservationState),
                    CreatedAt = DateTime.UtcNow.AddDays(-10),
                    SubmittedAt = DateTime.UtcNow.AddDays(-10),
                    ApprovedAt = DateTime.UtcNow.AddDays(-9),
                    ReadyForPickupAt = DateTime.UtcNow.AddDays(-8),
                    PickedUpAt = DateTime.UtcNow.AddDays(-7),
                    ApprovedByPharmacistId = pharmacist.Id,
                    MarkedReadyByPharmacistId = pharmacist.Id,
                    MarkedPickedUpByPharmacistId = pharmacist.Id,
                    TotalAmount = (omega3?.Price ?? 0) + (zinc?.Price ?? 0) + magnesium.Price,
                    PatientPaysAmount = (omega3?.Price ?? 0) + (zinc?.Price ?? 0) + magnesium.Price,
                    InsurancePaysAmount = 0,
                    Items = new[]
                    {
                        new ReservationItem { ProductId = omega3?.Id ?? vitaminD.Id, Quantity = 1, UnitPrice = omega3?.Price ?? vitaminD.Price, LineTotal = omega3?.Price ?? vitaminD.Price, PatientPart = omega3?.Price ?? vitaminD.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = zinc?.Id ?? bComplex.Id, Quantity = 1, UnitPrice = zinc?.Price ?? bComplex.Price, LineTotal = zinc?.Price ?? bComplex.Price, PatientPart = zinc?.Price ?? bComplex.Price, InsurancePart = 0 },
                        new ReservationItem { ProductId = magnesium.Id, Quantity = 1, UnitPrice = magnesium.Price, LineTotal = magnesium.Price, PatientPart = magnesium.Price, InsurancePart = 0 }
                    }
                }
            };

            await context.Reservations.AddRangeAsync(testPatientReservations);
            await context.Reservations.AddRangeAsync(otherPatientReservations);
            await context.SaveChangesAsync();
        }
    }
}