using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;

public sealed class LogoutUseCase(
    ValidateSessionUseCase validateSessionUseCase,
    ISesionRepository sesionRepository,
    IAuditoriaSeguridadRepository auditoriaSeguridadRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<LogoutResultDto>> ExecuteAsync(
        string? sessionToken,
        CancellationToken cancellationToken)
    {
        var sessionResult = await validateSessionUseCase.ExecuteAsync(sessionToken, cancellationToken);
        if (!sessionResult.Success || sessionResult.Data is null)
        {
            return UseCaseResult<LogoutResultDto>.Fail(
                sessionResult.ErrorCode ?? SeguridadErrorCodes.SessionRequired,
                sessionResult.Message);
        }

        var now = dateTimeProvider.Now;
        await sesionRepository.CloseAsync(sessionResult.Data.SesionId, SeguridadEventCodes.Logout, now, cancellationToken);
        await auditoriaSeguridadRepository.RegisterAsync(
            new AuditoriaSeguridadEvent
            {
                UsuarioAfectadoId = sessionResult.Data.UsuarioId,
                UsuarioAccionId = sessionResult.Data.UsuarioId,
                Evento = SeguridadEventCodes.Logout,
                Descripcion = "Cierre de sesion manual.",
                IpOrigen = null
            },
            cancellationToken);

        return UseCaseResult<LogoutResultDto>.Ok(new LogoutResultDto("Sesion cerrada correctamente."));
    }
}
