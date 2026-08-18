namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class EntradaInventarioDetalle
{
    public long Id { get; init; }

    public long EntradaInventarioId { get; init; }

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public decimal Cantidad { get; init; }

    public decimal CostoUnitario { get; init; }

    public decimal CostoTotal { get; init; }

    public decimal StockActual { get; init; }

    public string UnidadMedidaCodigo { get; init; } = string.Empty;

    public string UnidadMedidaNombre { get; init; } = string.Empty;

    public string? Observacion { get; init; }
}
