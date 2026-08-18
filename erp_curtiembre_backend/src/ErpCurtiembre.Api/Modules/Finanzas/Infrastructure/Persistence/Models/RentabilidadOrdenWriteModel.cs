namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class RentabilidadOrdenWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public decimal PrecioVenta { get; set; }

    public decimal CostoTotal { get; set; }

    public decimal? MargenPorcentaje { get; set; }

    public DateTime CalculadoEn { get; set; }
}
