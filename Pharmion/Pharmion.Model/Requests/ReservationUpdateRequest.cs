namespace Pharmion.Model.Requests
{
    public class ReservationUpdateRequest
    {
        // Pacijent može mijenjati samo draft rezervacije
        public string? Note { get; set; }
    }
}