using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Shared.Time;

public sealed class TimeOptions
{
    public const string SectionName = "Time";

    [Required]
    public string TimeZoneId { get; init; } = string.Empty;
}
