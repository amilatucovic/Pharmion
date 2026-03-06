using Pharmion.Model.Enums;
using System.Collections.Generic;
using System;

namespace Pharmion.Model.Responses
{
    public class PrescriptionResponse
    {
        public int Id { get; set; }
        public int PatientId { get; set; }
        public string PatientName { get; set; } = string.Empty;
        public int CreatedByPharmacistId { get; set; }
        public string PharmacistName { get; set; } = string.Empty;
        public string DoctorName { get; set; } = string.Empty;
        public string? Facility { get; set; }
        public DateTime IssuedAt { get; set; }
        public DateTime? ValidFrom { get; set; }
        public DateTime? ValidTo { get; set; }
        public PrescriptionStatus Status { get; set; }
        public string StatusDisplay { get; set; } = string.Empty;
        public string? Notes { get; set; }
        public List<PrescriptionItemResponse> Items { get; set; } = new List<PrescriptionItemResponse>();
    }
}