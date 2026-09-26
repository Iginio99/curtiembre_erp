namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class ProductoTerminado
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public long OrdenProduccionId { get; init; }

    public string OrdenCodigo { get; init; } = string.Empty;

    public long CalidadProductoId { get; init; }

    public string CalidadCodigo { get; init; } = string.Empty;

    public string CalidadNombre { get; init; } = string.Empty;

    public DateTime FechaIngreso { get; init; }

    public decimal CantidadPielesBuenas { get; init; }

    public decimal CantidadLadosCalculada { get; init; }

    public decimal CantidadLadosA { get; init; }

    public decimal CantidadLadosB { get; init; }

    public decimal CantidadLadosC { get; init; }

    public decimal CantidadLadosMerma { get; init; }

    public string Estado { get; init; } = string.Empty;

    public string? Observacion { get; init; }
}
