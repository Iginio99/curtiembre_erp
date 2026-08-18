namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class SolicitudInsumoWriteModel
{
    public long Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public long OrdenProduccionId { get; set; }
    public long OrdenProcesoId { get; set; }
    public string Estado { get; set; } = string.Empty;
    public string? Observacion { get; set; }
    public DateTime SolicitadoEn { get; set; }
    public long SolicitadoPorUsuarioId { get; set; }
}

public sealed class SolicitudInsumoDetalleWriteModel
{
    public long Id { get; set; }
    public long SolicitudInsumoId { get; set; }
    public long InsumoId { get; set; }
    public decimal CantidadSolicitada { get; set; }
    public string? Observacion { get; set; }
}
