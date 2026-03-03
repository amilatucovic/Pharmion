using System;

namespace Pharmion.Model.Exceptions
{
    public class EarlyDispenseRequiredException : Exception
    {
        public DateTime NextEligibleDate { get; }
        public int DaysRemaining { get; }

        public EarlyDispenseRequiredException(string message, DateTime nextEligibleDate, int daysRemaining)
            : base(message)
        {
            NextEligibleDate = nextEligibleDate;
            DaysRemaining = daysRemaining;
        }
    }
}