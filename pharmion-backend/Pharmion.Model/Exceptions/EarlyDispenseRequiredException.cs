using System;

namespace Pharmion.Model.Exceptions
{
    public class EarlyDispenseRequiredException : UserException
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