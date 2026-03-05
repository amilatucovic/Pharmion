namespace Pharmion.Model.SearchObjects
{
    public class PatientSearchObject : BaseSearchObject
    {
        public string? Name { get; set; }
        public string? JMBG { get; set; }
        public bool? IsInsured { get; set; }
        public int? CityId { get; set; }
    }
}