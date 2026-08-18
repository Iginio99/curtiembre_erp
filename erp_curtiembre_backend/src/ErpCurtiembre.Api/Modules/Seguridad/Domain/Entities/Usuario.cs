namespace ErpCurtiembre.Modules.Seguridad.Domain.Entities;

public sealed class Usuario
{
    public long Id { get; init; }

    public long RolId { get; init; }

    public long? AreaId { get; init; }

    public string Nombres { get; init; } = string.Empty;

    public string Apellidos { get; init; } = string.Empty;

    public string Dni { get; init; } = string.Empty;

    public string UserName { get; init; } = string.Empty;

    public string PasswordHash { get; init; } = string.Empty;

    public bool DebeCambiarPassword { get; init; }

    public int IntentosFallidos { get; init; }

    public DateTime? BloqueadoHasta { get; init; }

    public DateTime? UltimoLoginEn { get; init; }

    public bool Activo { get; init; }

    public DateTime CreadoEn { get; init; }

    public long? CreadoPorUsuarioId { get; init; }

    public DateTime? ActualizadoEn { get; init; }

    public long? ActualizadoPorUsuarioId { get; init; }

    public string? RolCodigo { get; init; }

    public string? RolNombre { get; init; }

    public string? AreaNombre { get; init; }

    public string NombreCompleto => $"{Nombres} {Apellidos}".Trim();

    public bool EstaBloqueado(DateTime now) => BloqueadoHasta.HasValue && BloqueadoHasta.Value > now;
}
