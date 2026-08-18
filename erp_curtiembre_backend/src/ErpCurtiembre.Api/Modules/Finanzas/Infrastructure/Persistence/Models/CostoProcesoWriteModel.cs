namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class CostoProcesoWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long OrdenProcesoId { get; set; }

    public decimal CostoInsumos { get; set; }

    public decimal CostoManoObra { get; set; }

    public DateTime CalculadoEn { get; set; }
}
