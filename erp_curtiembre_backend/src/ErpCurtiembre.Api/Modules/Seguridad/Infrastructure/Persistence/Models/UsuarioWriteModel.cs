namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;

public sealed class UsuarioWriteModel
{
    public long Id { get; set; }

    public long RolId { get; set; }

    public long? AreaId { get; set; }

    public string Nombres { get; set; } = string.Empty;

    public string Apellidos { get; set; } = string.Empty;

    public string Dni { get; set; } = string.Empty;

    public string Usuario { get; set; } = string.Empty;

    public string PasswordHash { get; set; } = string.Empty;

    public bool DebeCambiarPassword { get; set; }

    public int IntentosFallidos { get; set; }

    public DateTime? BloqueadoHasta { get; set; }

    public DateTime? UltimoLoginEn { get; set; }

    public bool Activo { get; set; }

    public DateTime CreadoEn { get; set; }

    public long? CreadoPorUsuarioId { get; set; }

    public DateTime? ActualizadoEn { get; set; }

    public long? ActualizadoPorUsuarioId { get; set; }
}
