namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class PeriodoCostoWriteModel
{
    public long Id { get; set; }

    public int Anio { get; set; }

    public int Mes { get; set; }

    public DateTime FechaInicio { get; set; }

    public DateTime FechaFin { get; set; }

    public string Estado { get; set; } = "ABIERTO";

    public DateTime? CerradoEn { get; set; }

    public long? CerradoPorUsuarioId { get; set; }

    public string? Observacion { get; set; }
}
