namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class OrdenCompra
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public long ProveedorId { get; init; }

    public string ProveedorRazonSocial { get; init; } = string.Empty;

    public DateTime FechaEmision { get; init; }

    public DateTime? FechaAprobacion { get; init; }

    public long? AprobadoPorUsuarioId { get; init; }

    public string Estado { get; init; } = string.Empty;

    public string? Observacion { get; init; }

    public string? Motivo { get; init; }

    public DateTime CreadoEn { get; init; }

    public long? CreadoPorUsuarioId { get; init; }

    public DateTime? ActualizadoEn { get; init; }

    public long? ActualizadoPorUsuarioId { get; init; }

    public int TotalItems { get; init; }

    public decimal CantidadTotalSolicitada { get; init; }

    public decimal CantidadTotalRecibida { get; init; }

    public decimal MontoTotalEstimado { get; init; }
}
