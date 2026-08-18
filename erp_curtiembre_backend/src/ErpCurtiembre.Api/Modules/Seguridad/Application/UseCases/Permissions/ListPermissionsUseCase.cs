using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;

public sealed class ListPermissionsUseCase(IPermisoRepository permisoRepository)
{
    public async Task<IReadOnlyCollection<PermissionDto>> ExecuteAsync(
        PermissionFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await permisoRepository.ListAsync(filters, cancellationToken);
        return items
            .Select(item => new PermissionDto(item.Id, item.Codigo, item.Modulo, item.Accion, item.Descripcion, item.Activo))
            .ToArray();
    }
}
