namespace ErpCurtiembre.Modules.Seguridad.Domain.Entities;

public sealed class SesionActiva
{
    public long SesionId { get; init; }

    public long UsuarioId { get; init; }

    public long RolId { get; init; }

    public string Usuario { get; init; } = string.Empty;

    public string Nombres { get; init; } = string.Empty;

    public string Apellidos { get; init; } = string.Empty;

    public string RolCodigo { get; init; } = string.Empty;

    public string RolNombre { get; init; } = string.Empty;

    public bool UsuarioActivo { get; init; }

    public bool RolActivo { get; init; }

    public bool DebeCambiarPassword { get; init; }

    public DateTime ExpiraEn { get; init; }

    public string NombreCompleto => $"{Nombres} {Apellidos}".Trim();
}
