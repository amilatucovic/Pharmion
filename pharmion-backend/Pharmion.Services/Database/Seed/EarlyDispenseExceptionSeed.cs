using Microsoft.EntityFrameworkCore;
using Pharmion.Model.Enums;
using Pharmion.Services.Database.Entities;

namespace Pharmion.Services.Database.Seed
{
    public class EarlyDispenseExceptionSeed : IEntitySeeder<EarlyDispenseException>
    {
        public async Task SeedAsync(PharmionDbContext context)
        {
            if (await context.EarlyDispenseExceptions.AnyAsync())
                return;

            var pharmacist = await context.Pharmacists
                .FirstOrDefaultAsync(p => p.Username == "pharmacist");
            if (pharmacist == null) return;

            var patient = await context.Patients
                .FirstOrDefaultAsync(p => p.Username == "patient");
            if (patient == null) return;

            
            var amlodipinPrescItem = await context.PrescriptionItems
                .Include(pi => pi.Prescription)
                .FirstOrDefaultAsync(pi =>
                    pi.Prescription.PatientId == patient.Id &&
                    pi.Product.Name.Contains("Amlodipin"));
            if (amlodipinPrescItem == null) return;

            
            var metforminPrescItem = await context.PrescriptionItems
                .Include(pi => pi.Prescription)
                .FirstOrDefaultAsync(pi =>
                    pi.Prescription.PatientId == patient.Id &&
                    pi.Product.Name.Contains("Metformin"));
            if (metforminPrescItem == null) return;

           
            var pickedUpReservation = await context.Reservations
                .Include(r => r.Items)
                .FirstOrDefaultAsync(r =>
                    r.PatientId == patient.Id &&
                    r.ReservationState == "PickedUpReservationState" &&
                    r.Items.Any(i => i.PrescriptionItemId == amlodipinPrescItem.Id));
            if (pickedUpReservation == null) return;


            var submittedReservation = await context.Reservations.Include(r => r.Items)
                                      .FirstOrDefaultAsync(r => r.PatientId == patient.Id && r.ReservationState == "SubmittedReservationState");
            if (submittedReservation == null) return;

            var exceptions = new[]
            {
                
                new EarlyDispenseException
                {
                    PrescriptionItemId = amlodipinPrescItem.Id,
                    ReservationId = pickedUpReservation.Id,
                    RequestedAt = DateTime.UtcNow.AddDays(-42),
                    Status = ExceptionStatus.Approved,
                    ReasonType = EarlyDispenseReasonType.Urgent,
                    OtherReason = null,
                    Note = "Approved — patient ran out of medication while travelling.",
                    ApprovedAt = DateTime.UtcNow.AddDays(-42),
                    ApprovedByPharmacistId = pharmacist.Id
                },
               
                new EarlyDispenseException
                {
                    PrescriptionItemId = metforminPrescItem.Id,
                    ReservationId = submittedReservation.Id,
                    RequestedAt = DateTime.UtcNow.AddDays(-4),
                    Status = ExceptionStatus.Pending,
                    ReasonType = EarlyDispenseReasonType.DoctorRecommendation,
                    OtherReason = null,
                    Note = null,
                    ApprovedAt = null,
                    ApprovedByPharmacistId = null
                }
            };

            await context.EarlyDispenseExceptions.AddRangeAsync(exceptions);
            await context.SaveChangesAsync();
        }
    }
}