using System;


namespace Pharmion.Model.Exceptions
{
    public class ForbiddenException : Exception
    {
        public ForbiddenException(string message = "Access denied.") : base(message) { }
    }
}
