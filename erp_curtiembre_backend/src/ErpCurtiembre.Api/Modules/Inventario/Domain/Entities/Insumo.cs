namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class Insumo
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Nombre { get; init; } = string.Empty;

    public string TipoBien { get; init; } = string.Empty;

    public string? Presentacion { get; init; }

    public long UnidadMedidaId { get; init; }

    public string UnidadMedidaCodigo { get; init; } = string.Empty;

    public string UnidadMedidaNombre { get; init; } = string.Empty;

    public decimal StockMinimo { get; init; }

    public decimal CostoPromedioActual { get; init; }

    public decimal StockActual { get; init; }

    public bool RequiereLote { get; init; }

    public bool Activo { get; init; }

    public DateTime CreadoEn { get; init; }

    public long? CreadoPorUsuarioId { get; init; }

    public DateTime? ActualizadoEn { get; init; }

    public long? ActualizadoPorUsuarioId { get; init; }
}
