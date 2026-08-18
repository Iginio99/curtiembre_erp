namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class SalidaInventarioWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string TipoSalida { get; set; } = string.Empty;

    public long? OrdenProduccionId { get; set; }

    public long? OrdenProcesoId { get; set; }

    public DateTime FechaSalida { get; set; }

    public string? Motivo { get; set; }

    public string? Observacion { get; set; }

    public string Estado { get; set; } = string.Empty;

    public long? CreadoPorUsuarioId { get; set; }

    public DateTime CreadoEn { get; set; }
}
