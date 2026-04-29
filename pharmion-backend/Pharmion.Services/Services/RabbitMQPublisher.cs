using EasyNetQ;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Pharmion.Services.Interfaces;


namespace Pharmion.Services.Services
{
    public class RabbitMQPublisher : IRabbitMQPublisher, IDisposable
    {
        private readonly IBus _bus;
        private readonly ILogger<RabbitMQPublisher> _logger;
        private bool _disposed = false;

        public RabbitMQPublisher(IConfiguration configuration, ILogger<RabbitMQPublisher> logger)
        {
            _logger = logger;
            var connectionString = configuration["RABBITMQ_CONNECTIONSTRING"]
               ?? throw new InvalidOperationException("RABBITMQ_CONNECTIONSTRING not configured");

            _bus = RabbitHutch.CreateBus(connectionString);
            _logger.LogInformation("RabbitMQ publisher initialized");
        }

        public async Task PublishAsync<T>(T message, string topic) where T : class
        {
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2)); 
            try
            {
                await _bus.PubSub.PublishAsync(message, x => x.WithTopic(topic), cts.Token);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error publishing message to topic: {Topic}", topic);
            }
        }

        public void Dispose()
        {
            if (!_disposed)
            {
                _bus?.Dispose();
                _disposed = true;
            }
        }
    }
}