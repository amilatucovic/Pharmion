using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;
using Pharmion.Model.Enums;

namespace Pharmion.Services.Database.Entities
{
    public class PrescriptionItem
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(Prescription))]
        public int PrescriptionId { get; set; }
        public Prescription? Prescription { get; set; }

        [ForeignKey(nameof(Product))]
        public int ProductId { get; set; }
        public Product? Product { get; set; } 

        [Required, MaxLength(100)]
        public string Dosage { get; set; } = string.Empty; 

        public int QuantityPerPeriod { get; set; }  
        public int PeriodDays { get; set; }

      
        public int Repeats { get; set; }            
        public int RepeatsUsed { get; set; }

        public TherapyType TherapyType { get; set; }

        public DateTime? LastDispensedAt { get; set; }
        public DateTime? NextEligibleDispenseAt { get; set; } 

        public ICollection<ReservationItem> ReservationItems { get; set; } = new List<ReservationItem>();
        public ICollection<EarlyDispenseException> EarlyDispenseExceptions { get; set; } = new List<EarlyDispenseException>();
        public ICollection<DispenseEvent> DispenseEvents { get; set; } = new List<DispenseEvent>();
    }
}
