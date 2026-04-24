using Pharmion.Model.Enums;
using System;

namespace Pharmion.Model.Responses
{
    public class EarlyDispenseExceptionResponse
    {
        public int Id { get; set; }

        public int PrescriptionItemId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string Dosage { get; set; } = string.Empty;
        public int PeriodDays { get; set; }
        public DateTime? NextEligibleDispenseAt { get; set; }
        public DateTime? LastDispensedAt { get; set; }

        public int ReservationId { get; set; }
        public string PatientName { get; set; } = string.Empty;
        public string PatientEmail { get; set; } = string.Empty;
        public string PharmacyName { get; set; } = string.Empty;
        public int PharmacyId { get; set; }

        public DateTime RequestedAt { get; set; }
        public ExceptionStatus Status { get; set; }
        public string StatusDisplay => Status.ToString();
        public EarlyDispenseReasonType ReasonType { get; set; }
        public string ReasonTypeDisplay => ReasonType.ToString();
        public string? OtherReason { get; set; }
        public string? Note { get; set; }

        public DateTime? ApprovedAt { get; set; }
        public string? ApprovedByPharmacistName { get; set; }
    }
}