namespace Pharmion.Model.SearchObjects
{
    public class PharmacySearchObject : BaseSearchObject
    {
        public string Name { get; set; } = string.Empty;
        public bool? IsActive { get; set; }
        public int? CityId { get; set; }
    }
}
