namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class PrecioSugeridoWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public decimal CostoBaseSinIgv { get; set; }

    public decimal MargenPorcentaje { get; set; }

    public decimal IgvPorcentaje { get; set; }

    public DateTime CalculadoEn { get; set; }
}
