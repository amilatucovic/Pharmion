using Microsoft.EntityFrameworkCore;
using Pharmion.Services.Database.Entities;
using System.Collections.Generic;
using System.Reflection.Emit;

namespace Pharmion.Services.Database
{
    public class PharmionDbContext : DbContext
    {
        public PharmionDbContext(DbContextOptions<PharmionDbContext> options) : base(options)
        {
        }

        public DbSet<ChronicDisease> ChronicDiseases { get; set; }
        public DbSet<City> Cities { get; set; }
        public DbSet<DispenseEvent> DispenseEvents { get; set; }
        public DbSet<EarlyDispenseException> EarlyDispenseExceptions { get; set; }
        public DbSet<InventoryItem> InventoryItems { get; set; }
        public DbSet<MedicationCategory> MedicationCategories { get; set; }
        public DbSet<MedicationDetail> MedicationDetails { get; set; }
        public DbSet<Notification> Notifications { get; set; }
        public DbSet<Patient> Patients { get; set; }
        public DbSet<PatientChronicDisease> PatientChronicDiseases { get; set; }
        public DbSet<Payment> Payments { get; set; }
        public DbSet<Pharmacist> Pharmacists { get; set; }
        public DbSet<Pharmacy> Pharmacies { get; set; }
        public DbSet<Prescription> Prescriptions { get; set; }
        public DbSet<PrescriptionItem> PrescriptionItems { get; set; }
        public DbSet<Product> Products { get; set; }
        public DbSet<Reservation> Reservations { get; set; }
        public DbSet<ReservationItem> ReservationItems { get; set; }
        public DbSet<StockMovement> StockMovements { get; set; }
        public DbSet<SupplementDetail> SupplementDetails { get; set; }
        public DbSet<TherapyReminder> TherapyReminders { get; set; }
        public DbSet<TherapySchedule> TherapySchedules { get; set; }
        public DbSet<TherapyScheduleTime> TherapyScheduleTimes { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<PharmacologicalCategory> PharmacologicalCategories { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<User>().ToTable("Users");
            modelBuilder.Entity<Patient>().ToTable("Patients");
            modelBuilder.Entity<Pharmacist>().ToTable("Pharmacists");

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            modelBuilder.Entity<User>()
                .HasIndex(u => u.Email)
                .IsUnique();

            modelBuilder.Entity<Product>()
               .HasOne(p => p.MedicationDetails)
               .WithOne(md => md.Product)
               .HasForeignKey<MedicationDetail>(md => md.ProductId)
               .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Product>()
                .HasOne(p => p.SupplementDetails)
                .WithOne(sd => sd.Product)
                .HasForeignKey<SupplementDetail>(sd => sd.ProductId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Payment)
                .WithOne(p => p.Reservation)
                .HasForeignKey<Payment>(p => p.ReservationId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Prescription>()
                .HasMany(p => p.Items)
                .WithOne(i => i.Prescription)
                .HasForeignKey(i => i.PrescriptionId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Prescription>()
                .HasOne(p => p.CreatedByPharmacist)
                .WithMany(ph => ph.Prescriptions)
                .HasForeignKey(p => p.CreatedByPharmacistId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Prescription>()
                .HasOne(p => p.Patient)
                .WithMany(pt => pt.Prescriptions)
                .HasForeignKey(p => p.PatientId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<Reservation>()
                .HasMany(r => r.Items)
                .WithOne(ri => ri.Reservation)
                .HasForeignKey(ri => ri.ReservationId)
                .OnDelete(DeleteBehavior.Cascade);

            
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Patient)
                .WithMany(p => p.Reservations)
                .HasForeignKey(r => r.PatientId)
                .OnDelete(DeleteBehavior.Restrict);

            
            modelBuilder.Entity<Reservation>()
                .HasOne(r => r.Pharmacy)
                .WithMany(ph => ph.Reservations)
                .HasForeignKey(r => r.PharmacyId)
                .OnDelete(DeleteBehavior.Restrict);

            
            modelBuilder.Entity<ReservationItem>()
                .HasOne(ri => ri.Product)
                .WithMany(p => p.ReservationItems)
                .HasForeignKey(ri => ri.ProductId)
                .OnDelete(DeleteBehavior.Restrict);

            
            modelBuilder.Entity<ReservationItem>()
                .HasOne(ri => ri.PrescriptionItem)
                .WithMany(pi => pi.ReservationItems)
                .HasForeignKey(ri => ri.PrescriptionItemId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<InventoryItem>()
                .HasOne(ii => ii.Pharmacy)
                .WithMany(p => p.InventoryItems)
                .HasForeignKey(ii => ii.PharmacyId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<InventoryItem>()
                .HasOne(ii => ii.Product)
                .WithMany(p => p.InventoryItems)
                .HasForeignKey(ii => ii.ProductId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<InventoryItem>()
                .HasIndex(ii => new { ii.PharmacyId, ii.ProductId })
                .IsUnique();

            modelBuilder.Entity<StockMovement>()
                .HasOne(sm => sm.InventoryItem)
                .WithMany(s => s.StockMovements) 
                .HasForeignKey(sm => sm.InventoryItemId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<StockMovement>()
                .HasOne(sm => sm.CreatedByPharmacist)
                .WithMany() 
                .HasForeignKey(sm => sm.CreatedByPharmacistId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<PatientChronicDisease>()
                .HasOne(pcd => pcd.Patient)
                .WithMany(p => p.ChronicDiseases)
                .HasForeignKey(pcd => pcd.PatientId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<PatientChronicDisease>()
                .HasOne(pcd => pcd.ChronicDisease)
                .WithMany(cd => cd.PatientChronicDiseases)
                .HasForeignKey(pcd => pcd.ChronicDiseaseId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<PatientChronicDisease>()
                .HasIndex(x => new { x.PatientId, x.ChronicDiseaseId })
                .IsUnique();

            modelBuilder.Entity<MedicationDetail>()
                .HasOne(md => md.MedicationCategory)
                .WithMany() 
                .HasForeignKey(md => md.MedicationCategoryId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<MedicationDetail>()
            .HasOne(md => md.PharmacologicalCategory)
            .WithMany(pc => pc.MedicationDetails)
            .HasForeignKey(md => md.PharmacologicalCategoryId)
            .OnDelete(DeleteBehavior.Restrict); 
        

          modelBuilder.Entity<EarlyDispenseException>()
                .HasOne(e => e.PrescriptionItem)
                .WithMany(pi => pi.EarlyDispenseExceptions)
                .HasForeignKey(e => e.PrescriptionItemId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<EarlyDispenseException>()
                .HasOne(e => e.Reservation)
                .WithMany() 
                .HasForeignKey(e => e.ReservationId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<EarlyDispenseException>()
                .HasOne(e => e.ApprovedByPharmacist)
                .WithMany(ph => ph.ApprovedEarlyDispenseExceptions)
                .HasForeignKey(e => e.ApprovedByPharmacistId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DispenseEvent>()
                .HasOne(d => d.Reservation)
                .WithMany(r => r.DispenseEvents)
                .HasForeignKey(d => d.ReservationId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DispenseEvent>()
                .HasOne(d => d.PrescriptionItem)
                .WithMany(pi => pi.DispenseEvents)
                .HasForeignKey(d => d.PrescriptionItemId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<DispenseEvent>()
                .HasOne(d => d.DispensedByPharmacist)
                .WithMany(ph => ph.DispenseEvents)
                .HasForeignKey(d => d.DispensedByPharmacistId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<TherapySchedule>()
               .HasOne(ts => ts.Patient)
               .WithMany(p => p.TherapySchedules)
               .HasForeignKey(ts => ts.PatientId)
               .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TherapySchedule>()
                .HasOne(ts => ts.Product)
                .WithMany() 
                .HasForeignKey(ts => ts.ProductId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<TherapySchedule>()
                .HasOne(ts => ts.PrescriptionItem)
                .WithMany() 
                .HasForeignKey(ts => ts.PrescriptionItemId)
                .OnDelete(DeleteBehavior.SetNull);

            modelBuilder.Entity<TherapySchedule>()
                .HasMany(ts => ts.Times)
                .WithOne(t => t.TherapySchedule)
                .HasForeignKey(t => t.TherapyScheduleId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TherapySchedule>()
                .HasMany(ts => ts.Reminders)
                .WithOne(r => r.TherapySchedule)
                .HasForeignKey(r => r.TherapyScheduleId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<TherapyReminder>()
                .HasIndex(r => new { r.TherapyScheduleId, r.ScheduledFor });

            modelBuilder.Entity<Notification>()
                .HasOne(n => n.User)
                .WithMany() 
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<Notification>()
                .HasIndex(n => new { n.UserId, n.CreatedAt });

            modelBuilder.Entity<ChronicDisease>()
                .HasIndex(cd => cd.Code)
                .IsUnique();

            
            modelBuilder.Entity<Product>()
                .Property(p => p.Price)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Payment>()
                .Property(p => p.Amount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.TotalAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.PatientPaysAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<Reservation>()
                .Property(r => r.InsurancePaysAmount)
                .HasPrecision(18, 2);

            modelBuilder.Entity<ReservationItem>()
                .Property(ri => ri.UnitPrice)
                .HasPrecision(18, 2);

            modelBuilder.Entity<ReservationItem>()
                .Property(ri => ri.LineTotal)
                .HasPrecision(18, 2);

            modelBuilder.Entity<ReservationItem>()
                .Property(ri => ri.PatientPart)
                .HasPrecision(18, 2);

            modelBuilder.Entity<ReservationItem>()
                .Property(ri => ri.InsurancePart)
                .HasPrecision(18, 2);

            
            modelBuilder.Entity<MedicationCategory>()
                .Property(mc => mc.PatientPaymentPercentage)
                .HasPrecision(5, 2);

            modelBuilder.Entity<MedicationCategory>()
                .Property(mc => mc.InsurancePaymentPercentage)
                .HasPrecision(5, 2);

            modelBuilder.Entity<MedicationCategory>()
                .Property(mc => mc.FlatFee)
                .HasPrecision(18, 2);



        }



    }
}

