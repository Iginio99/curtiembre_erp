namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class CostoOrden
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public string OrdenProduccionCodigo { get; init; } = string.Empty;

    public long? PeriodoCostoId { get; init; }

    public int? PeriodoAnio { get; init; }

    public int? PeriodoMes { get; init; }

    public decimal CostoPieles { get; init; }

    public decimal CostoInsumos { get; init; }

    public decimal CostoManoObra { get; init; }

    public decimal CostoIndirectoAsignado { get; init; }

    public decimal CostoDepreciacionAsignado { get; init; }

    public decimal CostoTotal { get; init; }

    public decimal? PielesBuenasFinales { get; init; }

    public decimal? CostoPorPiel { get; init; }

    public decimal? CostoEstimado { get; init; }

    public decimal? CostoReal { get; init; }

    public string Estado { get; init; } = string.Empty;

    public DateTime CalculadoEn { get; init; }

    public long? CalculadoPorUsuarioId { get; init; }
}
