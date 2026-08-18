namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class StockInsumoWriteModel
{
    public long Id { get; set; }

    public long InsumoId { get; set; }

    public decimal CantidadActual { get; set; }

    public decimal CostoPromedioActual { get; set; }

    public DateTime ActualizadoEn { get; set; }
}
