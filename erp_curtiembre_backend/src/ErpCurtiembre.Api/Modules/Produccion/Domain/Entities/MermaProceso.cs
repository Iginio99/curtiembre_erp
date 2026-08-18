namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class MermaProceso
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public long OrdenProcesoId { get; init; }

    public long ProcesoProductivoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public decimal CantidadPerdida { get; init; }

    public string? Motivo { get; init; }

    public string? Observacion { get; init; }

    public DateTime RegistradoEn { get; init; }

    public long? RegistradoPorUsuarioId { get; init; }

    public string? RegistradoPorNombre { get; init; }
}
