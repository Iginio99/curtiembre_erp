using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;

namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface IPermisoRepository
{
    Task<IReadOnlyCollection<Permiso>> ListAsync(PermissionFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Permiso>> GetPermissionsByUserAsync(long usuarioId, CancellationToken cancellationToken);

    Task<bool> UserHasPermissionAsync(long usuarioId, string permissionCode, CancellationToken cancellationToken);
}
