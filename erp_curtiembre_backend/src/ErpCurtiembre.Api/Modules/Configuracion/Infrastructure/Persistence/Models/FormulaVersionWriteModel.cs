namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;

public sealed class FormulaVersionWriteModel
{
    public long Id { get; set; }

    public long FormulaId { get; set; }

    public int NumeroVersion { get; set; }

    public DateTime FechaInicioVigencia { get; set; }

    public DateTime? FechaFinVigencia { get; set; }

    public bool Vigente { get; set; }

    public string? Observacion { get; set; }

    public DateTime CreadoEn { get; set; }

    public long? CreadoPorUsuarioId { get; set; }
}
