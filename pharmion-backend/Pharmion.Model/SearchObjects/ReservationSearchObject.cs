using System;

namespace Pharmion.Model.SearchObjects
{
    public class ReservationSearchObject : BaseSearchObject
    {
        public int? PatientId { get; set; }
        public string? PatientName { get; set; }
        public int? PharmacyId { get; set; }
        public string? ReservationState { get; set; }
        public DateTime? CreatedFrom { get; set; }
        public DateTime? CreatedTo { get; set; }
        public bool ExcludeDraft { get; set; } = false;
    }
}
