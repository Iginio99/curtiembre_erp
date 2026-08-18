namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class StockActual
{
    public long InsumoId { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Nombre { get; init; } = string.Empty;

    public string TipoBien { get; init; } = string.Empty;

    public string UnidadMedidaCodigo { get; init; } = string.Empty;

    public string UnidadMedidaNombre { get; init; } = string.Empty;

    public decimal StockMinimo { get; init; }

    public decimal CantidadActual { get; init; }

    public decimal CostoPromedioActual { get; init; }

    public bool Activo { get; init; }

    public bool StockBajo { get; init; }

    public DateTime ActualizadoEn { get; init; }
}
