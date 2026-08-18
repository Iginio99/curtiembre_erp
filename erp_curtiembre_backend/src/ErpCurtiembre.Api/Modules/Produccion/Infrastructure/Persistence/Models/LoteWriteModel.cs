namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class LoteWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public long ClienteId { get; set; }

    public long TipoPielId { get; set; }

    public DateTime FechaIngreso { get; set; }

    public decimal CantidadPielesInicial { get; set; }

    public decimal CantidadPielesDisponible { get; set; }

    public bool ClienteTraeLote { get; set; }

    public decimal CostoPielesTotal { get; set; }

    public string? Observacion { get; set; }

    public string Estado { get; set; } = string.Empty;

    public DateTime CreadoEn { get; set; }

    public long? CreadoPorUsuarioId { get; set; }
}
