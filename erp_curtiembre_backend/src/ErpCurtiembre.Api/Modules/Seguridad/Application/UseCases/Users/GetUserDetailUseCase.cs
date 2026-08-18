using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Users;

public sealed class GetUserDetailUseCase(IUsuarioRepository usuarioRepository)
{
    public async Task<UseCaseResult<UserDetailDto>> ExecuteAsync(long usuarioId, CancellationToken cancellationToken)
    {
        var usuario = await usuarioRepository.FindByIdAsync(usuarioId, cancellationToken);
        if (usuario is null)
        {
            return UseCaseResult<UserDetailDto>.Fail(SeguridadErrorCodes.NotFound, "No se encontro el usuario.");
        }

        return UseCaseResult<UserDetailDto>.Ok(Map(usuario));
    }

    public static UserDetailDto Map(Domain.Entities.Usuario usuario) =>
        new(
            usuario.Id,
            usuario.Dni,
            usuario.Nombres,
            usuario.Apellidos,
            usuario.UserName,
            usuario.RolId,
            usuario.RolCodigo ?? string.Empty,
            usuario.RolNombre ?? string.Empty,
            usuario.AreaId,
            usuario.AreaNombre,
            usuario.Activo,
            usuario.DebeCambiarPassword,
            usuario.IntentosFallidos,
            usuario.BloqueadoHasta,
            usuario.UltimoLoginEn,
            usuario.CreadoEn);
}
