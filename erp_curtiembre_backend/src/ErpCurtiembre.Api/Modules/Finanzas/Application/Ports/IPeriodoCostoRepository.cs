using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface IPeriodoCostoRepository
{
    Task<bool> ExistsByYearMonthAsync(int anio, int mes, long? excludeId, CancellationToken cancellationToken);

    Task<PeriodoCosto?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(PeriodoCosto periodoCosto, CancellationToken cancellationToken);

    Task CloseAsync(long id, DateTime closedAt, long actorId, string? observacion, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<PeriodoCosto>> ListAsync(PeriodoCostoFiltersDto filters, CancellationToken cancellationToken);
}
