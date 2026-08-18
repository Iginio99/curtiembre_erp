namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class CostoProceso
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public string OrdenProduccionCodigo { get; init; } = string.Empty;

    public long OrdenProcesoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public decimal CostoInsumos { get; init; }

    public decimal CostoManoObra { get; init; }

    public decimal CostoTotal { get; init; }

    public DateTime CalculadoEn { get; init; }
}
