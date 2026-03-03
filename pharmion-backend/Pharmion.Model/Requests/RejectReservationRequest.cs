using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Model.Requests
{
    public class RejectReservationRequest
    {
        [Required]
        [MaxLength(500)]
        public string Reason { get; set; }
    }
}
