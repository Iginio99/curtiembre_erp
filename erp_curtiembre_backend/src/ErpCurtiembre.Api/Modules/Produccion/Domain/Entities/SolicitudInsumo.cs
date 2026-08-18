namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class SolicitudInsumo
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public long OrdenProduccionId { get; init; }

    public string OrdenCodigo { get; init; } = string.Empty;

    public long OrdenProcesoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public string Estado { get; init; } = string.Empty;

    public string? Observacion { get; init; }

    public DateTime SolicitadoEn { get; init; }

    public long SolicitadoPorUsuarioId { get; init; }

    public string SolicitadoPorNombre { get; init; } = string.Empty;
}

public sealed class SolicitudInsumoDetalle
{
    public long Id { get; init; }

    public long SolicitudInsumoId { get; init; }

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public string UnidadMedidaCodigo { get; init; } = string.Empty;

    public string UnidadMedidaNombre { get; init; } = string.Empty;

    public decimal CantidadSolicitada { get; init; }

    public string? Observacion { get; init; }
}
