using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;

public sealed class GetPermissionsByUserUseCase(IPermisoRepository permisoRepository)
{
    public async Task<UserPermissionsDto> ExecuteAsync(long usuarioId, CancellationToken cancellationToken)
    {
        var items = await permisoRepository.GetPermissionsByUserAsync(usuarioId, cancellationToken);
        return new UserPermissionsDto(usuarioId, items.Select(item => item.Codigo).ToArray());
    }
}
