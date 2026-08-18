namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class ProveedorWriteModel
{
    public long Id { get; set; }

    public string RucDocumento { get; set; } = string.Empty;

    public string RazonSocial { get; set; } = string.Empty;

    public string? Direccion { get; set; }

    public string? Telefono { get; set; }

    public string? Correo { get; set; }

    public string? Contacto { get; set; }

    public bool Activo { get; set; }

    public DateTime CreadoEn { get; set; }

    public DateTime? ActualizadoEn { get; set; }
}
