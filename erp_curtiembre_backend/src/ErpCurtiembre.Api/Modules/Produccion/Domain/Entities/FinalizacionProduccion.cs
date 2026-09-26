namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class FinalizacionProduccion
{
    public long OrdenProduccionId { get; init; }

    public long ControlCalidadId { get; init; }

    public long CalidadProductoId { get; init; }

    public string ProductoTerminadoCodigo { get; init; } = string.Empty;

    public decimal CantidadLados { get; init; }

    public decimal CantidadLadosA { get; init; }

    public decimal CantidadLadosB { get; init; }

    public decimal CantidadLadosC { get; init; }

    public decimal CantidadLadosMerma { get; init; }

    public string? Observacion { get; init; }

    public long ActorId { get; init; }

    public DateTime Timestamp { get; init; }
}
