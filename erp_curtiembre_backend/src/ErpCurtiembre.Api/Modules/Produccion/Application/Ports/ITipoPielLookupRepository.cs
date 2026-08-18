using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface ITipoPielLookupRepository
{
    Task<TipoPielLookup?> FindByIdAsync(long id, CancellationToken cancellationToken);
}
