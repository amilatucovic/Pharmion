using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class ReservationItem
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Reservation))]
        public int ReservationId { get; set; }
        public Reservation? Reservation { get; set; }

        [ForeignKey(nameof(Product))]
        public int ProductId { get; set; }
        public Product? Product { get; set; }

        public int Quantity { get; set; }

        public decimal UnitPrice { get; set; }
        public decimal LineTotal { get; set; }

        public decimal PatientPart { get; set; }
        public decimal InsurancePart { get; set; }

        [ForeignKey(nameof(PrescriptionItem))]
        public int? PrescriptionItemId { get; set; }
        public PrescriptionItem? PrescriptionItem { get; set; }

        public bool IsSubstitutionAllowed { get; set; }

    }
}
