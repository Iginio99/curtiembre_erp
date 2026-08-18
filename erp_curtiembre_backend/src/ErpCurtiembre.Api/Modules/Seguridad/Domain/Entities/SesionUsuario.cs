namespace ErpCurtiembre.Modules.Seguridad.Domain.Entities;

public sealed class SesionUsuario
{
    public long Id { get; init; }

    public long UsuarioId { get; init; }

    public string TokenHash { get; init; } = string.Empty;

    public string? IpOrigen { get; init; }

    public string? UserAgent { get; init; }

    public DateTime InicioEn { get; init; }

    public DateTime ExpiraEn { get; init; }

    public DateTime? CerradoEn { get; init; }

    public string? MotivoCierre { get; init; }

    public bool Activa { get; init; }
}
