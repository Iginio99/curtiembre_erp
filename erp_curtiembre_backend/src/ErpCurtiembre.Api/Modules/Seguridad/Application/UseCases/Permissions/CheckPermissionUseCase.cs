using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;

public sealed class CheckPermissionUseCase(
    IUsuarioRepository usuarioRepository,
    IPermisoRepository permisoRepository)
{
    public async Task<UseCaseResult<CheckPermissionResultDto>> ExecuteAsync(
        long usuarioId,
        string permissionCode,
        CancellationToken cancellationToken)
    {
        var usuario = await usuarioRepository.FindByIdAsync(usuarioId, cancellationToken);
        if (usuario is null)
        {
            return UseCaseResult<CheckPermissionResultDto>.Fail(
                SeguridadErrorCodes.NotFound,
                "No se encontro el usuario.");
        }

        if (!usuario.Activo)
        {
            return UseCaseResult<CheckPermissionResultDto>.Fail(
                SeguridadErrorCodes.InactiveUser,
                "El usuario esta inactivo.");
        }

        var allowed = await permisoRepository.UserHasPermissionAsync(usuarioId, permissionCode, cancellationToken);
        return UseCaseResult<CheckPermissionResultDto>.Ok(
            new CheckPermissionResultDto(usuarioId, permissionCode, allowed),
            allowed ? "Permiso concedido." : "Permiso denegado.");
    }
}
