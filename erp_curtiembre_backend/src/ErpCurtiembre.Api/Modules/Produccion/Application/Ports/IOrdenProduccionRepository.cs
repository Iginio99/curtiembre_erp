using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface IOrdenProduccionRepository
{
    Task<long> CreateAsync(
        OrdenProduccion orden,
        IReadOnlyCollection<ProcesoProductivoLookup> procesos,
        CancellationToken cancellationToken);

    Task<OrdenProduccion?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<OrdenProduccion>> ListAsync(
        OrdenProduccionFiltersDto filters,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<OrdenProduccionProceso>> ListProcessesAsync(
        long ordenId,
        CancellationToken cancellationToken);

    Task<OrdenProduccionProceso?> FindProcessByIdAsync(long processId, CancellationToken cancellationToken);

    Task StartOrderAsync(
        long orderId,
        long? responsableUsuarioId,
        decimal pesoBaseKg,
        DateTime fechaFinEstimada,
        string? observacion,
        DateTime startedAt,
        CancellationToken cancellationToken);

    Task CancelOrderAsync(
        long orderId,
        string motivo,
        long actorId,
        DateTime timestamp,
        CancellationToken cancellationToken);

    Task StartProcessAsync(
        long processId,
        long? responsableUsuarioId,
        decimal pesoBaseKg,
        DateTime fechaFinEstimada,
        string? observacion,
        DateTime startedAt,
        CancellationToken cancellationToken);

    Task MarkProcessReadyToStartAsync(long processId, CancellationToken cancellationToken);

    Task ExecuteProcessAsync(long processId, DateTime startedAt, CancellationToken cancellationToken);

    Task FinishProcessAsync(
        long processId,
        string? observacion,
        DateTime finishedAt,
        CancellationToken cancellationToken);

    Task UpdateProcessObservationAsync(
        long processId,
        string? observacion,
        CancellationToken cancellationToken);
}
