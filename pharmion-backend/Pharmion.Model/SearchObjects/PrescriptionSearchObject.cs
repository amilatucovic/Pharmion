using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.SearchObjects
{
    public class PrescriptionSearchObject : BaseSearchObject
    {
        public int? PatientId { get; set; }
        public int? CreatedByPharmacistId { get; set; }
        public string? DoctorName { get; set; }
        public PrescriptionStatus? Status { get; set; }
        public DateTime? IssuedFrom { get; set; }
        public DateTime? IssuedTo { get; set; }
    }
}