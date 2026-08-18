namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class PeriodoCosto
{
    public long Id { get; init; }

    public int Anio { get; init; }

    public int Mes { get; init; }

    public DateTime FechaInicio { get; init; }

    public DateTime FechaFin { get; init; }

    public string Estado { get; init; } = "ABIERTO";

    public DateTime? CerradoEn { get; init; }

    public long? CerradoPorUsuarioId { get; init; }

    public string? Observacion { get; init; }

    public decimal TotalIndirectos { get; init; }
}
