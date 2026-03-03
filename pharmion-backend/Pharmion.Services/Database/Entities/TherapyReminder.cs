using Pharmion.Model.Enums;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace Pharmion.Services.Database.Entities
{
    public class TherapyReminder
    {
        [Key]
        public int Id { get; set; }

        [ForeignKey(nameof(TherapySchedule))]
        public int TherapyScheduleId { get; set; }
        public TherapySchedule? TherapySchedule { get; set; }
        public DateTime ScheduledFor { get; set; } // npr. 2026-02-09 08:00 UTC

        public ReminderStatus Status { get; set; } = ReminderStatus.Upcoming;

        public DateTime? AcknowledgedAt { get; set; } 
    }
}
