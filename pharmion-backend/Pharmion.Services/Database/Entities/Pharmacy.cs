using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Runtime.CompilerServices;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class Pharmacy
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string Name { get; set; } = string.Empty;

        [Required]
        public string Address { get; set; } = string.Empty;

        [Required]
        [ForeignKey(nameof(City))]
        public int CityId { get; set; }
        public City? City { get; set; }

        public bool IsActive { get; set; } = true;

        [MaxLength(100)]
        public string? WorkingHours { get; set; }

        public ICollection<InventoryItem> InventoryItems { get; set; } = new List<InventoryItem>();
        public ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
    }
}
