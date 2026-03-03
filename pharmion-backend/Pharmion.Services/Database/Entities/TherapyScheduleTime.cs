using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class TherapyScheduleTime
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(TherapySchedule))]
        public int TherapyScheduleId { get; set; }
        public TherapySchedule? TherapySchedule { get; set; }

        public TimeSpan TimeOfDay { get; set; } // npr. 08:00, 20:00

        public bool IsActive { get; set; } = true;
    }
}
