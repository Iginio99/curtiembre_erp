using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface IConsumoProduccionRepository
{
    Task<bool> HasPlannedConsumptionAsync(long orderId, CancellationToken cancellationToken);

    Task RegisterPlannedConsumptionAsync(
        IReadOnlyCollection<OrdenConsumoPlanificado> items,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<OrdenConsumoPlanificado>> ListPlannedAsync(
        long orderId,
        CancellationToken cancellationToken);

    Task RegisterRealConsumptionAsync(
        IReadOnlyCollection<OrdenConsumoReal> realItems,
        IReadOnlyCollection<DesviacionConsumo> desviaciones,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<OrdenConsumoReal>> ListRealAsync(
        long orderId,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<DesviacionConsumo>> ListDeviationsAsync(
        long orderId,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ConsumoRealAcumulado>> ListAccumulatedRealByProcessAsync(
        long orderId,
        long processId,
        CancellationToken cancellationToken);
}
