namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class OrdenProduccionProceso
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public string OrdenEstado { get; init; } = string.Empty;

    public long ProcesoProductivoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public int Secuencia { get; init; }

    public long? ResponsableUsuarioId { get; init; }

    public string? ResponsableNombre { get; init; }

    public decimal? PesoBaseKg { get; init; }

    public DateTime? FechaFinEstimada { get; init; }

    public DateTime? FechaInicio { get; init; }

    public DateTime? FechaFin { get; init; }

    public int? DiasReales { get; init; }

    public string Estado { get; init; } = string.Empty;

    public string? Observacion { get; init; }
}
