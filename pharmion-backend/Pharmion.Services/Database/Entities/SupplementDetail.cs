using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class SupplementDetail
    {
        [Key, ForeignKey(nameof(Product))]
        public int ProductId { get; set; }
        public Product? Product { get; set; }

        public Gender? TargetGender { get; set; }
        public int? MinAge { get; set; }
        public int? MaxAge { get; set; }

        [MaxLength(200)]
        public string? Tags { get; set; } 
    }
}
