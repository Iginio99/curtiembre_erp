namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class OrdenProduccionProcesoWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long ProcesoProductivoId { get; set; }

    public int Secuencia { get; set; }

    public long? ResponsableUsuarioId { get; set; }

    public decimal? PesoBaseKg { get; set; }

    public DateTime? FechaFinEstimada { get; set; }

    public DateTime? FechaInicio { get; set; }

    public DateTime? FechaFin { get; set; }

    public string Estado { get; set; } = string.Empty;

    public string? Observacion { get; set; }

    public DateTime CreadoEn { get; set; }
}
