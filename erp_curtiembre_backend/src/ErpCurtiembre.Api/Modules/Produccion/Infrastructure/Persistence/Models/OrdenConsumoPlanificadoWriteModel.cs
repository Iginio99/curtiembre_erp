namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class OrdenConsumoPlanificadoWriteModel
{
    public long Id { get; set; }

    public long OrdenProduccionId { get; set; }

    public long OrdenProcesoId { get; set; }

    public long FormulaVersionId { get; set; }

    public long InsumoId { get; set; }

    public decimal Porcentaje { get; set; }

    public decimal CantidadPlanificada { get; set; }

    public DateTime CreadoEn { get; set; }
}
