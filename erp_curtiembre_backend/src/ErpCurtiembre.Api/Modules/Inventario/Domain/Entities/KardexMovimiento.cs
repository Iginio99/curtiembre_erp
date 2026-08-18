namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class KardexMovimiento
{
    public long Id { get; init; }

    public DateTime FechaMovimiento { get; init; }

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public string TipoMovimiento { get; init; } = string.Empty;

    public string? DocumentoTipo { get; init; }

    public long? DocumentoId { get; init; }

    public decimal Entrada { get; init; }

    public decimal Salida { get; init; }

    public decimal StockActual { get; init; }

    public string? EstadoStock { get; init; }

    public decimal CostoUnitario { get; init; }

    public decimal CostoTotal { get; init; }

    public long? UsuarioResponsableId { get; init; }

    public string? UsuarioResponsable { get; init; }

    public string? Observacion { get; init; }
}
