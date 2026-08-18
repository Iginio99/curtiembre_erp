namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class ClienteWriteModel
{
    public long Id { get; set; }

    public string RucDocumento { get; set; } = string.Empty;

    public string RazonSocial { get; set; } = string.Empty;

    public string? Direccion { get; set; }

    public string? Celular { get; set; }

    public string? Correo { get; set; }

    public string? Contacto { get; set; }

    public bool Activo { get; set; }

    public DateTime CreadoEn { get; set; }

    public DateTime? ActualizadoEn { get; set; }
}
