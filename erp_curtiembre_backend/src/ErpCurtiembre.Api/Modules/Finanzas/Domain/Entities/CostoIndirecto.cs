namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class CostoIndirecto
{
    public long Id { get; init; }

    public long PeriodoCostoId { get; init; }

    public int PeriodoAnio { get; init; }

    public int PeriodoMes { get; init; }

    public string PeriodoEstado { get; init; } = "ABIERTO";

    public string TipoCosto { get; init; } = string.Empty;

    public string? Descripcion { get; init; }

    public decimal Monto { get; init; }

    public DateTime RegistradoEn { get; init; }

    public long? RegistradoPorUsuarioId { get; init; }
}
