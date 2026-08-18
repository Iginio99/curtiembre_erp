using Microsoft.Extensions.Options;

namespace ErpCurtiembre.Shared.Time;

public sealed class PeruDateTimeProvider : IDateTimeProvider
{
    private readonly TimeZoneInfo _timeZone;

    public PeruDateTimeProvider(IOptions<TimeOptions> options)
    {
        var configuredTimeZoneId = options.Value.TimeZoneId.Trim();
        _timeZone = ResolveTimeZone(configuredTimeZoneId);
    }

    public DateTime UtcNow => DateTime.UtcNow;

    public DateTime Now => TimeZoneInfo.ConvertTimeFromUtc(UtcNow, _timeZone);

    public string TimeZoneId => _timeZone.Id;

    private static TimeZoneInfo ResolveTimeZone(string configuredTimeZoneId)
    {
        var candidateIds = new[]
        {
            configuredTimeZoneId,
            "America/Lima",
            "SA Pacific Standard Time"
        };

        foreach (var candidateId in candidateIds.Where(id => !string.IsNullOrWhiteSpace(id)).Distinct(StringComparer.OrdinalIgnoreCase))
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById(candidateId);
            }
            catch (TimeZoneNotFoundException)
            {
            }
            catch (InvalidTimeZoneException)
            {
            }
        }

        throw new InvalidOperationException(
            "No se pudo resolver la zona horaria configurada para Peru. Configura Time:TimeZoneId con un valor valido.");
    }
}
