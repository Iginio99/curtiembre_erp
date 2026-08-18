namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class DesviacionConsumo
{
    public long Id { get; init; }

    public long? OrdenConsumoPlanificadoId { get; init; }

    public long OrdenConsumoRealId { get; init; }

    public long OrdenProduccionId { get; init; }

    public long OrdenProcesoId { get; init; }

    public long ProcesoProductivoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public decimal CantidadPlanificada { get; init; }

    public decimal CantidadReal { get; init; }

    public decimal CantidadDesviacion { get; init; }

    public string? Motivo { get; init; }

    public DateTime RegistradoEn { get; init; }
}
