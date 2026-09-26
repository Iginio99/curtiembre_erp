namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class ControlCalidadWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long? ProductoTerminadoId { get; set; }

    public long CalidadProductoId { get; set; }

    public decimal CantidadLadosA { get; set; }

    public decimal CantidadLadosB { get; set; }

    public decimal CantidadLadosC { get; set; }

    public decimal CantidadLadosMerma { get; set; }

    public string Resultado { get; set; } = string.Empty;

    public string? Observacion { get; set; }

    public DateTime EvaluadoEn { get; set; }

    public long? EvaluadoPorUsuarioId { get; set; }
}
