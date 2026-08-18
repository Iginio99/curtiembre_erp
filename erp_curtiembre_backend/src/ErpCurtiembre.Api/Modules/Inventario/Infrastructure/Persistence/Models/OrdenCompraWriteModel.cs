namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class OrdenCompraWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public long ProveedorId { get; set; }

    public DateTime FechaEmision { get; set; }

    public DateTime? FechaAprobacion { get; set; }

    public long? AprobadoPorUsuarioId { get; set; }

    public string Estado { get; set; } = string.Empty;

    public string? Observacion { get; set; }

    public string? MotivoAnulacion { get; set; }

    public DateTime CreadoEn { get; set; }

    public long? CreadoPorUsuarioId { get; set; }

    public DateTime? ActualizadoEn { get; set; }

    public long? ActualizadoPorUsuarioId { get; set; }
}
