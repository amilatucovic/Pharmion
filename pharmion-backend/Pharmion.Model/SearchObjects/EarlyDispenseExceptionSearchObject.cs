using Pharmion.Model.Enums;

namespace Pharmion.Model.SearchObjects
{
    public class EarlyDispenseExceptionSearchObject : BaseSearchObject
    {
        public int? PharmacyId { get; set; }
        public int? PatientId { get; set; }
        public ExceptionStatus? Status { get; set; }
        public EarlyDispenseReasonType? ReasonType { get; set; }
        public string? PatientName { get; set; }
    }
}