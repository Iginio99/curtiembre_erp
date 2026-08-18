namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class DepreciacionPeriodo
{
    public long Id { get; init; }

    public long PeriodoCostoId { get; init; }

    public int PeriodoAnio { get; init; }

    public int PeriodoMes { get; init; }

    public long ActivoDepreciableId { get; init; }

    public string ActivoCodigo { get; init; } = string.Empty;

    public string ActivoNombre { get; init; } = string.Empty;

    public decimal MontoDepreciacion { get; init; }

    public DateTime CalculadoEn { get; init; }
}
