using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Model.Requests
{
    public class PharmacyUpsertRequest
    {
        [Required]
        [MaxLength(200, ErrorMessage = "Name must not exceed 200 characters.")]
        public string Name { get; set; } = string.Empty;

        [Required]
        [MaxLength(300, ErrorMessage = "Address must not exceed 300 characters.")]
        public string Address { get; set; } = string.Empty;

        [Required(ErrorMessage = "City is required.")]
        public int CityId { get; set; }

        public bool IsActive { get; set; } = true;
    }
}
