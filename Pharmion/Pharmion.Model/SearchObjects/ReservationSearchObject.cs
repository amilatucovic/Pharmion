using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.SearchObjects
{
    public class ReservationSearchObject : BaseSearchObject
    {
        public int? PatientId { get; set; }
        public int? PharmacyId { get; set; }
        public string? ReservationState { get; set; }
        public DateTime? CreatedFrom { get; set; }
        public DateTime? CreatedTo { get; set; }
    }
}
