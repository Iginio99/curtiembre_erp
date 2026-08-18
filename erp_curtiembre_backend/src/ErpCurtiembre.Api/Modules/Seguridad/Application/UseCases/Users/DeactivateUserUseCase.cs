using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Users;

public sealed class DeactivateUserUseCase(
    ValidateSessionUseCase validateSessionUseCase,
    CheckPermissionUseCase checkPermissionUseCase,
    IUsuarioRepository usuarioRepository,
    ISesionRepository sesionRepository,
    IAuditoriaSeguridadRepository auditoriaSeguridadRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<LogoutResultDto>> ExecuteAsync(
        string? sessionToken,
        long usuarioId,
        string? motivo,
        CancellationToken cancellationToken)
    {
        var actorResult = await validateSessionUseCase.ExecuteAsync(sessionToken, cancellationToken);
        if (!actorResult.Success || actorResult.Data is null)
        {
            return UseCaseResult<LogoutResultDto>.Fail(
                actorResult.ErrorCode ?? SeguridadErrorCodes.SessionRequired,
                actorResult.Message);
        }

        var permissionResult = await checkPermissionUseCase.ExecuteAsync(
            actorResult.Data.UsuarioId,
            SeguridadPermissionCodes.UsuariosAdmin,
            cancellationToken);

        if (!permissionResult.Success || permissionResult.Data?.Allowed != true)
        {
            return UseCaseResult<LogoutResultDto>.Fail(
                SeguridadErrorCodes.PermissionDenied,
                "No tienes permiso para desactivar usuarios.");
        }

        var usuario = await usuarioRepository.FindByIdAsync(usuarioId, cancellationToken);
        if (usuario is null)
        {
            return UseCaseResult<LogoutResultDto>.Fail(SeguridadErrorCodes.NotFound, "No se encontro el usuario.");
        }

        var now = dateTimeProvider.Now;
        await usuarioRepository.DeactivateAsync(usuarioId, actorResult.Data.UsuarioId, now, cancellationToken);
        await sesionRepository.CloseAllByUserAsync(usuarioId, SeguridadEventCodes.UsuarioDesactivado, now, cancellationToken);

        await auditoriaSeguridadRepository.RegisterAsync(
            new AuditoriaSeguridadEvent
            {
                UsuarioAfectadoId = usuarioId,
                UsuarioAccionId = actorResult.Data.UsuarioId,
                Evento = SeguridadEventCodes.UsuarioDesactivado,
                Descripcion = motivo ?? "Usuario desactivado.",
                IpOrigen = null
            },
            cancellationToken);

        return UseCaseResult<LogoutResultDto>.Ok(new LogoutResultDto("Usuario desactivado correctamente."));
    }
}
