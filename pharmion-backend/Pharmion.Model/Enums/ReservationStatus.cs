using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.Enums
{
    public enum ReservationStatus
    {
        Draft = 1, 
        Submitted = 2, 
        Approved = 3, 
        ReadyForPickup = 4,
        PickedUp = 5, 
        Cancelled = 6, 
        Rejected = 7

    }
}
