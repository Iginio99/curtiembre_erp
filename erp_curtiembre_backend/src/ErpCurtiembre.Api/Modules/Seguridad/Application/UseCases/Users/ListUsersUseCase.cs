using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Users;

public sealed class ListUsersUseCase(IUsuarioRepository usuarioRepository)
{
    public async Task<IReadOnlyCollection<UserListItemDto>> ExecuteAsync(
        UserFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await usuarioRepository.ListAsync(filters, cancellationToken);
        return items
            .Select(item => new UserListItemDto(
                item.Id,
                item.Dni,
                item.Nombres,
                item.Apellidos,
                item.UserName,
                item.RolId,
                item.RolNombre ?? string.Empty,
                item.AreaId,
                item.AreaNombre,
                item.Activo,
                item.DebeCambiarPassword,
                item.IntentosFallidos,
                item.BloqueadoHasta,
                item.UltimoLoginEn))
            .ToArray();
    }
}
