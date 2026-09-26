namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class OrdenProduccion
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public long LoteId { get; init; }

    public string LoteCodigo { get; init; } = string.Empty;

    public long ClienteId { get; init; }

    public string ClienteRazonSocial { get; init; } = string.Empty;

    public decimal CantidadPieles { get; init; }

    public DateTime? FechaInicioPlanificada { get; init; }

    public DateTime? FechaInicioReal { get; init; }

    public DateTime FechaFinEstimada { get; init; }

    public DateTime? FechaFinReal { get; init; }

    public long? ResponsableUsuarioId { get; init; }

    public string? ResponsableNombre { get; init; }

    public string? ResponsableCargo { get; init; }

    public string Estado { get; init; } = string.Empty;

    public string? MotivoAnulacion { get; init; }

    public string? Observacion { get; init; }

    public int ProcesosTotales { get; init; }

    public int ProcesosFinalizados { get; init; }

    public DateTime CreadoEn { get; init; }

    public long? CreadoPorUsuarioId { get; init; }

    public DateTime? ActualizadoEn { get; init; }

    public long? ActualizadoPorUsuarioId { get; init; }
}
