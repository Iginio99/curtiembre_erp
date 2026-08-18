namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class Proveedor
{
    public long Id { get; init; }

    public string RucDocumento { get; init; } = string.Empty;

    public string RazonSocial { get; init; } = string.Empty;

    public string? Direccion { get; init; }

    public string? Telefono { get; init; }

    public string? Correo { get; init; }

    public string? Contacto { get; init; }

    public bool Activo { get; init; }

    public DateTime CreadoEn { get; init; }

    public DateTime? ActualizadoEn { get; init; }
}
