namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class OrdenConsumoReal
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public long OrdenProcesoId { get; init; }

    public long ProcesoProductivoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public long? SalidaInventarioDetalleId { get; init; }

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public decimal CantidadConsumida { get; init; }

    public decimal CostoUnitario { get; init; }

    public decimal CostoTotal { get; init; }

    public bool EsExtra { get; init; }

    public DateTime CreadoEn { get; init; }
}
