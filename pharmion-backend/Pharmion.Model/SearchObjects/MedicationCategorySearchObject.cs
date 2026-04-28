using Pharmion.Model.Enums;

namespace Pharmion.Model.SearchObjects
{
    public class MedicationCategorySearchObject : BaseSearchObject
    {
        public CategoryCode? Code { get; set; }
        public string Name { get; set; } = string.Empty;
    }
}
