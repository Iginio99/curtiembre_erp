namespace ErpCurtiembre.Modules.Seguridad.Domain.Entities;

public sealed class Permiso
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Modulo { get; init; } = string.Empty;

    public string Accion { get; init; } = string.Empty;

    public string? Descripcion { get; init; }

    public bool Activo { get; init; }
}
