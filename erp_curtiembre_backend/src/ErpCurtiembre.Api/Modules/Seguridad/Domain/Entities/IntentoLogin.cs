namespace ErpCurtiembre.Modules.Seguridad.Domain.Entities;

public sealed class IntentoLogin
{
    public string UsuarioLogin { get; init; } = string.Empty;

    public long? UsuarioId { get; init; }

    public bool FueExitoso { get; init; }

    public string? IpOrigen { get; init; }

    public string? Mensaje { get; init; }
}
