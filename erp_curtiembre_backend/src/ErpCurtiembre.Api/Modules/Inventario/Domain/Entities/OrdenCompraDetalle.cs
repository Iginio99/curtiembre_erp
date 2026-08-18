namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class OrdenCompraDetalle
{
    public long Id { get; init; }

    public long OrdenCompraId { get; init; }

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public string UnidadMedidaCodigo { get; init; } = string.Empty;

    public string UnidadMedidaNombre { get; init; } = string.Empty;

    public decimal CantidadSolicitada { get; init; }

    public decimal CantidadRecibida { get; init; }

    public decimal SaldoPendiente { get; init; }

    public decimal? CostoUnitarioEstimado { get; init; }

    public decimal MontoEstimado { get; init; }

    public string? Observacion { get; init; }
}
