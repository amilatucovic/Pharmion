using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class Reservation
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Patient))]
        public int PatientId { get; set; }
        public Patient? Patient { get; set; }

        [ForeignKey(nameof(Pharmacy))]
        public int PharmacyId { get; set; }
        public Pharmacy? Pharmacy { get; set; }

        public ReservationStatus Status { get; set; } = ReservationStatus.Draft;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? SubmittedAt { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public DateTime? ReadyForPickupAt { get; set; }
        public DateTime? PickedUpAt { get; set; }

        public decimal TotalAmount { get; set; }
        public decimal PatientPaysAmount { get; set; }
        public decimal InsurancePaysAmount { get; set; }

        public DateTime? PickupDeadline { get; set; }

        public ICollection<ReservationItem> Items { get; set; } = new List<ReservationItem>();

        public Payment? Payment { get; set; }
        public ICollection<DispenseEvent> DispenseEvents { get; set; } = new List<DispenseEvent>();
    }
}
