using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface IProduccionFinanceLookupRepository
{
    Task<ProduccionProcesoLookup?> FindProcessAsync(long ordenProcesoId, CancellationToken cancellationToken);

    Task<ProduccionOrdenFinanceSnapshot?> FindOrderSnapshotAsync(long ordenProduccionId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ProduccionConsumoProcesoResumen>> ListConsumedCostByProcessAsync(
        long ordenProduccionId,
        CancellationToken cancellationToken);

    Task<ProduccionConsumoOrdenResumen?> GetConsumedCostByOrderAsync(
        long ordenProduccionId,
        CancellationToken cancellationToken);

    Task<ProduccionConsumoOrdenResumen?> GetPlannedCostByOrderAsync(
        long ordenProduccionId,
        CancellationToken cancellationToken);

    Task<decimal> GetTotalSkinsClosedInPeriodAsync(
        int anio,
        int mes,
        CancellationToken cancellationToken);
}
