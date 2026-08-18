using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface ICostoProcesoRepository
{
    Task<CostoProceso?> FindByOrderProcessIdAsync(long ordenProcesoId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<CostoProceso>> ListAsync(CostoProcesoFiltersDto filters, CancellationToken cancellationToken);

    Task UpsertAsync(CostoProceso costoProceso, CancellationToken cancellationToken);
}
