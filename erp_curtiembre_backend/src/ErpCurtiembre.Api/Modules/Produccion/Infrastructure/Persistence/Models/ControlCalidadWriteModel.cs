namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class ControlCalidadWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long? ProductoTerminadoId { get; set; }

    public long CalidadProductoId { get; set; }

    public string Resultado { get; set; } = string.Empty;

    public string? Observacion { get; set; }

    public DateTime EvaluadoEn { get; set; }

    public long? EvaluadoPorUsuarioId { get; set; }
}
