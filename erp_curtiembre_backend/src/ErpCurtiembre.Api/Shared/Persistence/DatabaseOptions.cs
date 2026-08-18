using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Shared.Persistence;

public sealed class DatabaseOptions
{
    public const string SectionName = "Database";

    [Required]
    public string DatabaseName { get; init; } = string.Empty;

    [Required]
    public string DefaultConnection { get; init; } = string.Empty;

    [MinLength(1)]
    public string[] Schemas { get; init; } = [];
}
