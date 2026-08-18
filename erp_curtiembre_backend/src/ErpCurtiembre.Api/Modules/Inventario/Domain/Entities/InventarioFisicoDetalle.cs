namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class InventarioFisicoDetalle
{
    public long Id { get; init; }

    public long InventarioFisicoId { get; init; }

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public decimal StockSistema { get; init; }

    public decimal StockContado { get; init; }

    public decimal Diferencia { get; init; }

    public string UnidadMedidaCodigo { get; init; } = string.Empty;

    public string UnidadMedidaNombre { get; init; } = string.Empty;

    public string? Observacion { get; init; }
}
