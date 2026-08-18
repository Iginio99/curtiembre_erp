namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class ProduccionConsumoProcesoResumen
{
    public long OrdenProduccionId { get; init; }

    public long OrdenProcesoId { get; init; }

    public decimal CostoInsumos { get; init; }
}
