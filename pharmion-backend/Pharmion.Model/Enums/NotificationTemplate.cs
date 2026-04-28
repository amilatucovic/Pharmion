using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.Enums
{
    public enum NotificationTemplate
    {
        ReservationSubmitted = 1,
        ReservationApproved = 2,
        ReservationRejected = 3,
        ReservationReadyForPickup = 4,
        ReservationCancelled = 5,
        NewReservationForPharmacist = 6,
        ReservationCancelledByPharmacist = 7,
        PaymentSelected = 8,
    }
}
