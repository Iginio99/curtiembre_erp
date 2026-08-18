namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class KardexMovimientoWriteModel
{
    public long Id { get; set; }

    public DateTime FechaMovimiento { get; set; }

    public long InsumoId { get; set; }

    public string TipoMovimiento { get; set; } = string.Empty;

    public string? DocumentoTipo { get; set; }

    public long? DocumentoId { get; set; }

    public decimal Entrada { get; set; }

    public decimal Salida { get; set; }

    public decimal StockActual { get; set; }

    public string? EstadoStock { get; set; }

    public decimal CostoUnitario { get; set; }

    public decimal CostoTotal { get; set; }

    public long? UsuarioResponsableId { get; set; }

    public string? Observacion { get; set; }
}
