namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class InventarioFisicoDetalleWriteModel
{
    public long Id { get; set; }

    public long InventarioFisicoId { get; set; }

    public long InsumoId { get; set; }

    public decimal StockSistema { get; set; }

    public decimal StockContado { get; set; }

    public string? Observacion { get; set; }
}
