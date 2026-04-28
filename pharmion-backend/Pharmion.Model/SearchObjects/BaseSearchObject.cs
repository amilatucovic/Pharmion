namespace Pharmion.Model.SearchObjects
{
    public class BaseSearchObject
    {
        public string? FTS { get; set; }
        public int? Page { get; set; } = 0;
        public int? PageSize { get; set; } = 10;
        public bool IncludeTotalCount { get; set; } = false;
        public bool RetrieveAll { get; set; } = false;
        public string? OrderBy { get; set; } = null;
    }
}
