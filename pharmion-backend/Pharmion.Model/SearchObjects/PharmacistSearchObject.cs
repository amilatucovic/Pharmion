namespace Pharmion.Model.SearchObjects
{
    public class PharmacistSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public int? PharmacyId { get; set; }
        public bool? IsActive { get; set; }
        public bool? IsAdministrator { get; set; }
    }
}