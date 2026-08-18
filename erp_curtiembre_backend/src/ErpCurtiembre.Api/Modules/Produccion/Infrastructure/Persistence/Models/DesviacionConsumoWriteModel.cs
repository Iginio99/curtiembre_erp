namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;

public sealed class DesviacionConsumoWriteModel
{
    public long Id { get; set; }

    public long? OrdenConsumoPlanificadoId { get; set; }

    public long OrdenConsumoRealId { get; set; }

    public decimal CantidadPlanificada { get; set; }

    public decimal CantidadReal { get; set; }

    public string? Motivo { get; set; }

    public DateTime RegistradoEn { get; set; }
}
