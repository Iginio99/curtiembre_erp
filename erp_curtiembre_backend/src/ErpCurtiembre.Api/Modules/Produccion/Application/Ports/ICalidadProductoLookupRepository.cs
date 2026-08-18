using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface ICalidadProductoLookupRepository
{
    Task<CalidadProductoLookup?> FindActiveByIdAsync(long id, CancellationToken cancellationToken);
}
