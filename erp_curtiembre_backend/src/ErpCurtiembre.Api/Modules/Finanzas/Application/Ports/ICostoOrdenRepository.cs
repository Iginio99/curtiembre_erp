using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface ICostoOrdenRepository
{
    Task<CostoOrden?> FindByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<CostoOrden>> ListAsync(CostoOrdenFiltersDto filters, CancellationToken cancellationToken);

    Task UpsertAsync(CostoOrden costoOrden, CancellationToken cancellationToken);
}
