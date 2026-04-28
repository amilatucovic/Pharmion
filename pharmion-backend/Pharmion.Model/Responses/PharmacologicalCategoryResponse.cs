using System;

namespace Pharmion.Model.Responses
{
    public class PharmacologicalCategoryResponse
    {
        public int Id { get; set; }
        public string Code { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }
}
