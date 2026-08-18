namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class OrdenProduccionWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public long LoteId { get; set; }

    public long ClienteId { get; set; }

    public decimal CantidadPieles { get; set; }

    public DateTime? FechaInicioPlanificada { get; set; }

    public DateTime? FechaInicioReal { get; set; }

    public DateTime FechaFinEstimada { get; set; }

    public DateTime? FechaFinReal { get; set; }

    public long? ResponsableUsuarioId { get; set; }

    public string Estado { get; set; } = string.Empty;

    public string? MotivoAnulacion { get; set; }

    public string? Observacion { get; set; }

    public DateTime CreadoEn { get; set; }

    public long? CreadoPorUsuarioId { get; set; }

    public DateTime? ActualizadoEn { get; set; }

    public long? ActualizadoPorUsuarioId { get; set; }
}
