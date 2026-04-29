using Pharmion.Model.Exceptions;

public class NotFoundException : UserException
{
    public NotFoundException(string message) : base(message) { }
}