using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class DispenseEvent
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Reservation))]
        public int ReservationId { get; set; }
        public Reservation? Reservation { get; set; }

        [ForeignKey(nameof(PrescriptionItem))]
        public int? PrescriptionItemId { get; set; }
        public PrescriptionItem? PrescriptionItem { get; set; }

        public DateTime DispensedAt { get; set; } = DateTime.UtcNow;
        public int Quantity { get; set; }

        [ForeignKey(nameof(DispensedByPharmacist))]
        public int DispensedByPharmacistId { get; set; }
        public Pharmacist? DispensedByPharmacist { get; set; }
    }
}
