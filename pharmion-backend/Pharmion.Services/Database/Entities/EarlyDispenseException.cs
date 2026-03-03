using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class EarlyDispenseException
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(PrescriptionItem))]
        public int PrescriptionItemId { get; set; }
        public PrescriptionItem? PrescriptionItem { get; set; }

        [ForeignKey(nameof(Reservation))]
        public int ReservationId { get; set; }
        public Reservation? Reservation { get; set; }

        public DateTime RequestedAt { get; set; } = DateTime.UtcNow;

        public ExceptionStatus Status { get; set; } = ExceptionStatus.Pending;

        public EarlyDispenseReasonType ReasonType { get; set; }

        // Ako je ReasonType == Other
        [MaxLength(500)]
        public string? OtherReason { get; set; }

        [MaxLength(500)]
        public string? Note { get; set; }

        public DateTime? ApprovedAt { get; set; }

        [ForeignKey(nameof(ApprovedByPharmacist))]
        public int? ApprovedByPharmacistId { get; set; }
        public Pharmacist? ApprovedByPharmacist { get; set; }


    }

}
