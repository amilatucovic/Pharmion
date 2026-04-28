using System.Collections.Generic;
using System;

namespace Pharmion.Model.Requests
{
    public class PrescriptionUpsertRequest
    {
        public int PatientId { get; set; }
        public string DoctorName { get; set; } = string.Empty;
        public string? Facility { get; set; }
        public DateTime? ValidFrom { get; set; }
        public DateTime? ValidTo { get; set; }
        public string? Notes { get; set; }
        public List<PrescriptionItemUpsertRequest> Items { get; set; } = new List<PrescriptionItemUpsertRequest>();
    }
}