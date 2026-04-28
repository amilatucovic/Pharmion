using System.ComponentModel.DataAnnotations;

namespace Pharmion.Services.Database.Entities
{
    public class City
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string Name { get; set; } = string.Empty;

        [Required, MaxLength(20)]
        public string PostalCode { get; set; } = string.Empty;

    }
}
