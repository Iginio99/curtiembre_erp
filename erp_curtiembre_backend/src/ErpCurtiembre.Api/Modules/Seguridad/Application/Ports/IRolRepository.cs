using ErpCurtiembre.Modules.Seguridad.Domain.Entities;

namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface IRolRepository
{
    Task<Rol?> FindByIdAsync(long rolId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Rol>> ListActiveAsync(CancellationToken cancellationToken);
}
