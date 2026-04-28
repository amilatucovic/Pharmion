using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;

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

        [MaxLength(1000)]
        public string ReservationState { get; set; } = string.Empty;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? UpdatedAt { get; set; }
        public DateTime? SubmittedAt { get; set; }
        public DateTime? ApprovedAt { get; set; }
        public DateTime? ReadyForPickupAt { get; set; }
        public DateTime? PickedUpAt { get; set; }

        public decimal TotalAmount { get; set; }
        public decimal PatientPaysAmount { get; set; }
        public decimal InsurancePaysAmount { get; set; }


        public string? CancellationReason { get; set; }
        public DateTime? CancelledAt { get; set; }
        public int? CancelledByUserId { get; set; }

          
        public string? RejectionReason { get; set; }
        public DateTime? RejectedAt { get; set; }
        public int? RejectedByPharmacistId { get; set; }

        
        public int? ApprovedByPharmacistId { get; set; }

       
        public int? MarkedReadyByPharmacistId { get; set; }

        
        public int? MarkedPickedUpByPharmacistId { get; set; }

        public DateTime? PickupDeadline { get; set; }

        public ICollection<ReservationItem> Items { get; set; } = new List<ReservationItem>();

        public Payment? Payment { get; set; }
        public ICollection<DispenseEvent> DispenseEvents { get; set; } = new List<DispenseEvent>();
    }
}
