using System;
using System.Collections.Generic;
using System.Text;

namespace Pharmion.Model.Exceptions
{
    public class UserException : Exception
    {
        public UserException(string message) : base(message) { }
        public UserException(string message, Exception innerException) : base(message, innerException) { }
    }
}
