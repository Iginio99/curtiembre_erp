using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;

public sealed class ListRolesUseCase(IRolRepository rolRepository)
{
    public async Task<IReadOnlyCollection<RoleDto>> ExecuteAsync(CancellationToken cancellationToken)
    {
        var items = await rolRepository.ListActiveAsync(cancellationToken);
        return items
            .Select(item => new RoleDto(item.Id, item.Codigo, item.Nombre, item.Descripcion, item.Activo))
            .ToArray();
    }
}
