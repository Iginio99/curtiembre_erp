using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface IRentabilidadOrdenRepository
{
    Task<RentabilidadOrden?> FindByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken);

    Task UpsertAsync(RentabilidadOrden rentabilidadOrden, CancellationToken cancellationToken);
}
