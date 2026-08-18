namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class PrecioSugerido
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public string OrdenProduccionCodigo { get; init; } = string.Empty;

    public decimal CostoBaseSinIgv { get; init; }

    public decimal MargenPorcentaje { get; init; }

    public decimal PrecioSugeridoSinIgv { get; init; }

    public decimal IgvPorcentaje { get; init; }

    public decimal PrecioSugeridoConIgv { get; init; }

    public DateTime CalculadoEn { get; init; }
}
