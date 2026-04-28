namespace Pharmion.Services.Interfaces
{
    public interface IRabbitMQPublisher : IDisposable
    {
        Task PublishAsync<T>(T message, string topic) where T : class;
    }
}