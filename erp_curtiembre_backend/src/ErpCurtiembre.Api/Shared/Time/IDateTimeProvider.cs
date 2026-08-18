namespace ErpCurtiembre.Shared.Time;

public interface IDateTimeProvider
{
    DateTime UtcNow { get; }

    DateTime Now { get; }

    string TimeZoneId { get; }
}
