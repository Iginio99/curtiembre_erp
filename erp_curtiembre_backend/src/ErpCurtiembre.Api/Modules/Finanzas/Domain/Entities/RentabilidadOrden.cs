namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class RentabilidadOrden
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public string OrdenProduccionCodigo { get; init; } = string.Empty;

    public decimal PrecioVenta { get; init; }

    public decimal CostoTotal { get; init; }

    public decimal Utilidad { get; init; }

    public decimal? MargenPorcentaje { get; init; }

    public DateTime CalculadoEn { get; init; }
}
