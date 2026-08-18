using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;

public sealed class ValidateSessionUseCase(
    ISessionTokenService sessionTokenService,
    ISesionRepository sesionRepository,
    IAuditoriaSeguridadRepository auditoriaSeguridadRepository,
    ILoginPolicyProvider loginPolicyProvider,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<SessionInfoDto>> ExecuteAsync(
        string? sessionToken,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(sessionToken))
        {
            return UseCaseResult<SessionInfoDto>.Fail(
                SeguridadErrorCodes.SessionRequired,
                "Se requiere una sesion activa.");
        }

        var hashedToken = sessionTokenService.HashToken(sessionToken);
        var sesion = await sesionRepository.FindActiveByTokenHashAsync(hashedToken, cancellationToken);
        if (sesion is null)
        {
            return UseCaseResult<SessionInfoDto>.Fail(
                SeguridadErrorCodes.SessionExpired,
                "La sesion no existe o ya no esta activa.");
        }

        var now = dateTimeProvider.Now;
        var loginPolicy = await loginPolicyProvider.GetAsync(cancellationToken);
        if (!sesion.UsuarioActivo || !sesion.RolActivo)
        {
            await sesionRepository.CloseAsync(sesion.SesionId, SeguridadEventCodes.SesionExpirada, now, cancellationToken);
            return UseCaseResult<SessionInfoDto>.Fail(
                SeguridadErrorCodes.InactiveUser,
                "La sesion pertenece a un usuario o rol inactivo.");
        }

        if (sesion.ExpiraEn <= now)
        {
            await sesionRepository.CloseAsync(sesion.SesionId, SeguridadEventCodes.SesionExpirada, now, cancellationToken);
            await auditoriaSeguridadRepository.RegisterAsync(
                new Domain.Entities.AuditoriaSeguridadEvent
                {
                    UsuarioAfectadoId = sesion.UsuarioId,
                    UsuarioAccionId = sesion.UsuarioId,
                    Evento = SeguridadEventCodes.SesionExpirada,
                    Descripcion = "Sesion expirada por tiempo.",
                    IpOrigen = null
                },
                cancellationToken);

            return UseCaseResult<SessionInfoDto>.Fail(
                SeguridadErrorCodes.SessionExpired,
                "La sesion expiro.");
        }

        var newExpiration = now.AddMinutes(loginPolicy.MinutosSesion);
        await sesionRepository.RefreshExpirationAsync(sesion.SesionId, newExpiration, cancellationToken);

        return UseCaseResult<SessionInfoDto>.Ok(
            new SessionInfoDto(
                sesion.SesionId,
                sesion.UsuarioId,
                sesion.RolId,
                sesion.Usuario,
                sesion.NombreCompleto,
                sesion.RolCodigo,
                sesion.RolNombre,
                sesion.DebeCambiarPassword,
                newExpiration),
            "Sesion valida.");
    }
}
