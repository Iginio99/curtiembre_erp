namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class ProductoTerminadoWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public long OrdenProduccionId { get; set; }

    public long CalidadProductoId { get; set; }

    public DateTime FechaIngreso { get; set; }

    public decimal CantidadPielesBuenas { get; set; }

    public decimal CantidadLados { get; set; }

    public string Estado { get; set; } = string.Empty;

    public string? Observacion { get; set; }
}
