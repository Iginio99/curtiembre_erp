using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Users;

public sealed class UpdateUserUseCase(
    ValidateSessionUseCase validateSessionUseCase,
    CheckPermissionUseCase checkPermissionUseCase,
    IUsuarioRepository usuarioRepository,
    IRolRepository rolRepository,
    IAreaLookupRepository areaLookupRepository,
    IAuditoriaSeguridadRepository auditoriaSeguridadRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<UserMutationResultDto>> ExecuteAsync(
        string? sessionToken,
        long usuarioId,
        UpdateUserRequestDto request,
        CancellationToken cancellationToken)
    {
        var actorResult = await validateSessionUseCase.ExecuteAsync(sessionToken, cancellationToken);
        if (!actorResult.Success || actorResult.Data is null)
        {
            return UseCaseResult<UserMutationResultDto>.Fail(
                actorResult.ErrorCode ?? SeguridadErrorCodes.SessionRequired,
                actorResult.Message);
        }

        var permissionResult = await checkPermissionUseCase.ExecuteAsync(
            actorResult.Data.UsuarioId,
            SeguridadPermissionCodes.UsuariosAdmin,
            cancellationToken);

        if (!permissionResult.Success || permissionResult.Data?.Allowed != true)
        {
            return UseCaseResult<UserMutationResultDto>.Fail(
                SeguridadErrorCodes.PermissionDenied,
                "No tienes permiso para editar usuarios.");
        }

        var usuario = await usuarioRepository.FindByIdAsync(usuarioId, cancellationToken);
        if (usuario is null)
        {
            return UseCaseResult<UserMutationResultDto>.Fail(SeguridadErrorCodes.NotFound, "No se encontro el usuario.");
        }

        var errors = await ValidateUserRequestAsync(request, usuarioId, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<UserMutationResultDto>.Fail(
                SeguridadErrorCodes.Validation,
                string.Join(" ", errors));
        }

        await usuarioRepository.UpdateAsync(
            new Usuario
            {
                Id = usuarioId,
                RolId = request.RolId,
                AreaId = request.AreaId,
                Nombres = request.Nombres.Trim(),
                Apellidos = request.Apellidos.Trim(),
                Dni = request.Dni.Trim(),
                UserName = request.UserName.Trim(),
                ActualizadoEn = dateTimeProvider.Now,
                ActualizadoPorUsuarioId = actorResult.Data.UsuarioId
            },
            cancellationToken);

        var updated = await usuarioRepository.FindByIdAsync(usuarioId, cancellationToken);
        if (updated is null)
        {
            return UseCaseResult<UserMutationResultDto>.Fail(SeguridadErrorCodes.NotFound, "No se encontro el usuario actualizado.");
        }

        if (usuario.RolId != updated.RolId)
        {
            await auditoriaSeguridadRepository.RegisterAsync(
                new AuditoriaSeguridadEvent
                {
                    UsuarioAfectadoId = usuarioId,
                    UsuarioAccionId = actorResult.Data.UsuarioId,
                    Evento = SeguridadEventCodes.RolCambiado,
                    Descripcion = $"Rol cambiado de {usuario.RolCodigo} a {updated.RolCodigo}.",
                    IpOrigen = null
                },
                cancellationToken);
        }

        await auditoriaSeguridadRepository.RegisterAsync(
            new AuditoriaSeguridadEvent
            {
                UsuarioAfectadoId = usuarioId,
                UsuarioAccionId = actorResult.Data.UsuarioId,
                Evento = SeguridadEventCodes.UsuarioActualizado,
                Descripcion = $"Usuario actualizado. Rol actual: {updated.RolCodigo}.",
                IpOrigen = null
            },
            cancellationToken);

        return UseCaseResult<UserMutationResultDto>.Ok(new UserMutationResultDto(GetUserDetailUseCase.Map(updated)));
    }

    private async Task<IReadOnlyCollection<string>> ValidateUserRequestAsync(
        UpdateUserRequestDto request,
        long usuarioId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        if (await usuarioRepository.ExistsByDniAsync(request.Dni.Trim(), usuarioId, cancellationToken))
        {
            errors.Add("El DNI ya existe.");
        }

        if (await usuarioRepository.ExistsByUserNameAsync(request.UserName.Trim(), usuarioId, cancellationToken))
        {
            errors.Add("El username ya existe.");
        }

        var rol = await rolRepository.FindByIdAsync(request.RolId, cancellationToken);
        if (rol is null || !rol.Activo)
        {
            errors.Add("El rol no existe o esta inactivo.");
        }

        if (!await areaLookupRepository.ExistsActiveAsync(request.AreaId, cancellationToken))
        {
            errors.Add("El area no existe o esta inactiva.");
        }

        return errors;
    }
}
