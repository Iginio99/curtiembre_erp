namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class ControlCalidad
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public long? ProductoTerminadoId { get; init; }

    public long CalidadProductoId { get; init; }

    public string CalidadCodigo { get; init; } = string.Empty;

    public string CalidadNombre { get; init; } = string.Empty;

    public string Resultado { get; init; } = string.Empty;

    public string? Observacion { get; init; }

    public DateTime EvaluadoEn { get; init; }

    public long? EvaluadoPorUsuarioId { get; init; }

    public string? EvaluadoPorNombre { get; init; }
}
