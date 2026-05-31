using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;


namespace Pharmion.Services.Database.Seed
{
    public class PrescriptionSeed : IEntitySeeder<Prescription>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.Prescriptions.AnyAsync())
                return;

            var patient = await context.Patients.FirstOrDefaultAsync(p => p.Username == "patient");
            var pharmacist = await context.Pharmacists.FirstOrDefaultAsync(p => p.Username == "pharmacist");

            if (patient == null || pharmacist == null) return;

            var amlodipin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Amlodipin"));
            var metformin = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Metformin"));
            var salbutamol = await context.Products.FirstOrDefaultAsync(p => p.Name.Contains("Salbutamol"));

            if (amlodipin == null || metformin == null || salbutamol == null) return;

            var prescriptions = new[]
            {
                
                new Prescription
                {
                    PatientId = patient.Id,
                    CreatedByPharmacistId = pharmacist.Id,
                    DoctorName = "Almedina Omanović",
                    Facility = "Dom zdravlja Mostar",
                    IssuedAt = DateTime.UtcNow.AddDays(-30),
                    ValidFrom = DateTime.UtcNow.AddDays(-30),
                    ValidTo = DateTime.UtcNow.AddDays(335),
                    Status = PrescriptionStatus.Active,
                    Notes = "Chronic hypertension therapy. Take once daily in the morning.",
                    Items = new[]
                    {
                        new PrescriptionItem
                        {
                            ProductId = amlodipin.Id,
                            Dosage = "5 mg once daily",
                            QuantityPerPeriod = 30,
                            PeriodDays = 30,
                            Repeats = 12,
                            RepeatsUsed = 1,
                            TherapyType = TherapyType.ChronicQuarterly,
                            LastDispensedAt = DateTime.UtcNow.AddDays(-10),
                            NextEligibleDispenseAt = DateTime.UtcNow.AddDays(25)
                        }
                    }
                },
               
                new Prescription
                {
                    PatientId = patient.Id,
                    CreatedByPharmacistId = pharmacist.Id,
                    DoctorName = "Asja Kuko",
                    Facility = "Klinička bolnica Mostar",
                    IssuedAt = DateTime.UtcNow.AddDays(-60),
                    ValidFrom = DateTime.UtcNow.AddDays(-60),
                    ValidTo = DateTime.UtcNow.AddDays(305),
                    Status = PrescriptionStatus.Active,
                    Notes = "Type 2 diabetes therapy. Take with meals.",
                    Items = new[]
                    {
                        new PrescriptionItem
                        {
                            ProductId = metformin.Id,
                            Dosage = "850 mg twice daily",
                            QuantityPerPeriod = 60,
                            PeriodDays = 30,
                            Repeats = 12,
                            RepeatsUsed = 2,
                            TherapyType = TherapyType.ChronicMonthly,
                            LastDispensedAt = DateTime.UtcNow.AddDays(-15),
                            NextEligibleDispenseAt = DateTime.UtcNow.AddDays(20)
                        }
                    }
                },
                
                new Prescription
                {
                    PatientId = patient.Id,
                    CreatedByPharmacistId = pharmacist.Id,
                    DoctorName = "Ammar Tucović",
                    Facility = "Dom zdravlja Mostar",
                    IssuedAt = DateTime.UtcNow.AddDays(-10),
                    ValidFrom = DateTime.UtcNow.AddDays(-10),
                    ValidTo = DateTime.UtcNow.AddDays(355),
                    Status = PrescriptionStatus.Active,
                    Notes = "Use as needed for acute asthma attacks.",
                    Items = new[]
                    {
                        new PrescriptionItem
                        {
                            ProductId = salbutamol.Id,
                            Dosage = "100 mcg, 1–2 inhalations as needed",
                            QuantityPerPeriod = 1,
                            PeriodDays = 30,
                            Repeats = 6,
                            RepeatsUsed = 0,
                            TherapyType = TherapyType.Acute,
                            LastDispensedAt = null,
                            NextEligibleDispenseAt = null
                        }
                    }
                }
            };

            await context.Prescriptions.AddRangeAsync(prescriptions);
            await context.SaveChangesAsync();
        }
    }
}