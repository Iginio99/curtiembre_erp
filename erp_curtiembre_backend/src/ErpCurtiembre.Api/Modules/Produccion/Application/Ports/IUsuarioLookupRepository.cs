using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface IUsuarioLookupRepository
{
    Task<UsuarioLookup?> FindActiveByIdAsync(long id, CancellationToken cancellationToken);
}
