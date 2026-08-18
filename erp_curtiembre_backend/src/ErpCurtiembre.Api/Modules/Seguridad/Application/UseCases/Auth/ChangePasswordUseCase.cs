using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Modules.Seguridad.Domain.Rules;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;

public sealed class ChangePasswordUseCase(
    ValidateSessionUseCase validateSessionUseCase,
    IUsuarioRepository usuarioRepository,
    IPasswordHasher passwordHasher,
    IAuditoriaSeguridadRepository auditoriaSeguridadRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<LogoutResultDto>> ExecuteAsync(
        string? sessionToken,
        ChangePasswordRequestDto request,
        CancellationToken cancellationToken)
    {
        var sessionResult = await validateSessionUseCase.ExecuteAsync(sessionToken, cancellationToken);
        if (!sessionResult.Success || sessionResult.Data is null)
        {
            return UseCaseResult<LogoutResultDto>.Fail(
                sessionResult.ErrorCode ?? SeguridadErrorCodes.SessionRequired,
                sessionResult.Message);
        }

        var usuario = await usuarioRepository.FindByIdAsync(sessionResult.Data.UsuarioId, cancellationToken);
        if (usuario is null)
        {
            return UseCaseResult<LogoutResultDto>.Fail(SeguridadErrorCodes.NotFound, "No se encontro el usuario.");
        }

        if (!passwordHasher.VerifyPassword(request.CurrentPassword, usuario.PasswordHash))
        {
            return UseCaseResult<LogoutResultDto>.Fail(
                SeguridadErrorCodes.InvalidCredentials,
                "La contrasena actual no es valida.");
        }

        var errors = PasswordPolicyRule.Validate(request.NewPassword, request.ConfirmPassword);
        if (errors.Count > 0)
        {
            return UseCaseResult<LogoutResultDto>.Fail(
                SeguridadErrorCodes.Validation,
                string.Join(" ", errors));
        }

        await usuarioRepository.UpdatePasswordAsync(
            usuario.Id,
            passwordHasher.HashPassword(request.NewPassword),
            false,
            usuario.Id,
            dateTimeProvider.Now,
            cancellationToken);

        await auditoriaSeguridadRepository.RegisterAsync(
            new AuditoriaSeguridadEvent
            {
                UsuarioAfectadoId = usuario.Id,
                UsuarioAccionId = usuario.Id,
                Evento = SeguridadEventCodes.PasswordCambiado,
                Descripcion = "Cambio de contrasena exitoso.",
                IpOrigen = null
            },
            cancellationToken);

        return UseCaseResult<LogoutResultDto>.Ok(new LogoutResultDto("Contrasena actualizada correctamente."));
    }
}
