namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class AjusteInventarioDetalleWriteModel
{
    public long Id { get; set; }

    public long AjusteInventarioId { get; set; }

    public long InsumoId { get; set; }

    public decimal Cantidad { get; set; }

    public decimal? CostoUnitario { get; set; }
}
