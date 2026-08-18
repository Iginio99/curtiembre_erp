namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class OrdenConsumoRealWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long OrdenProcesoId { get; set; }

    public long? SalidaInventarioDetalleId { get; set; }

    public long InsumoId { get; set; }

    public decimal CantidadConsumida { get; set; }

    public decimal CostoUnitario { get; set; }

    public bool EsExtra { get; set; }

    public DateTime CreadoEn { get; set; }
}
