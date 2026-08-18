namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class CostoOrdenWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long? PeriodoCostoId { get; set; }

    public decimal CostoPieles { get; set; }

    public decimal CostoInsumos { get; set; }

    public decimal CostoManoObra { get; set; }

    public decimal CostoIndirectoAsignado { get; set; }

    public decimal CostoDepreciacionAsignado { get; set; }

    public decimal? PielesBuenasFinales { get; set; }

    public decimal? CostoPorPiel { get; set; }

    public decimal? CostoEstimado { get; set; }

    public decimal? CostoReal { get; set; }

    public string Estado { get; set; } = "ESTIMADO";

    public DateTime CalculadoEn { get; set; }

    public long? CalculadoPorUsuarioId { get; set; }
}
