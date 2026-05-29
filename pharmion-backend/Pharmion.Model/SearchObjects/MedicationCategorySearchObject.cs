using Pharmion.Model.Enums;

namespace Pharmion.Model.SearchObjects
{
    public class MedicationCategorySearchObject : BaseSearchObject
    {
        public int? Code { get; set; }       
        public string? CodeLabel { get; set; } 
        public string Name { get; set; } = string.Empty;
    }
}
