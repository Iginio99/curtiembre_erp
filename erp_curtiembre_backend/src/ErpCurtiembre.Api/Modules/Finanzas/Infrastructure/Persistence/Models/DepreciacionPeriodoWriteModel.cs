namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class DepreciacionPeriodoWriteModel
{
    public long Id { get; set; }

    public long PeriodoCostoId { get; set; }

    public long ActivoDepreciableId { get; set; }

    public decimal MontoDepreciacion { get; set; }

    public DateTime CalculadoEn { get; set; }
}
