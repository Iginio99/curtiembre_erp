using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Modules.Seguridad.Domain.Rules;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;

public sealed class LoginUseCase(
    IUsuarioRepository usuarioRepository,
    IPasswordHasher passwordHasher,
    ISessionTokenService sessionTokenService,
    ISesionRepository sesionRepository,
    ILoginAttemptRepository loginAttemptRepository,
    IAuditoriaSeguridadRepository auditoriaSeguridadRepository,
    ILoginPolicyProvider loginPolicyProvider,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<LoginResultDto>> ExecuteAsync(
        LoginRequestDto request,
        CancellationToken cancellationToken)
    {
        var now = dateTimeProvider.Now;
        var loginPolicy = await loginPolicyProvider.GetAsync(cancellationToken);
        var normalizedUserName = request.UserName.Trim();
        var usuario = await usuarioRepository.FindByUserNameAsync(normalizedUserName, cancellationToken);

        if (usuario is null)
        {
            await loginAttemptRepository.RegisterAsync(
                new IntentoLogin
                {
                    UsuarioLogin = normalizedUserName,
                    FueExitoso = false,
                    IpOrigen = request.Ip,
                    Mensaje = "Usuario o contrasena incorrectos."
                },
                cancellationToken);

            return UseCaseResult<LoginResultDto>.Fail(
                SeguridadErrorCodes.InvalidCredentials,
                "Usuario o contrasena incorrectos.");
        }

        if (!usuario.Activo)
        {
            await RegisterFailedAttemptAsync(usuario, request, "Usuario inactivo.", cancellationToken);
            return UseCaseResult<LoginResultDto>.Fail(SeguridadErrorCodes.InactiveUser, "El usuario esta inactivo.");
        }

        if (usuario.EstaBloqueado(now))
        {
            await RegisterFailedAttemptAsync(usuario, request, "Usuario bloqueado.", cancellationToken);
            return UseCaseResult<LoginResultDto>.Fail(
                SeguridadErrorCodes.UserBlocked,
                $"El usuario esta bloqueado hasta {usuario.BloqueadoHasta:yyyy-MM-dd HH:mm:ss}.");
        }

        if (!passwordHasher.VerifyPassword(request.Password, usuario.PasswordHash))
        {
            var intentos = await usuarioRepository.IncrementFailedAttemptsAsync(usuario.Id, cancellationToken);
            if (intentos >= loginPolicy.MaxIntentosFallidos)
            {
                var blockedUntil = now.AddMinutes(loginPolicy.MinutosBloqueo);
                await usuarioRepository.BlockUntilAsync(usuario.Id, blockedUntil, cancellationToken);
                await auditoriaSeguridadRepository.RegisterAsync(
                    new AuditoriaSeguridadEvent
                    {
                        UsuarioAfectadoId = usuario.Id,
                        UsuarioAccionId = usuario.Id,
                        Evento = SeguridadEventCodes.UsuarioBloqueado,
                        Descripcion = $"Usuario bloqueado por {loginPolicy.MaxIntentosFallidos} intentos fallidos.",
                        IpOrigen = request.Ip
                    },
                    cancellationToken);
            }

            await RegisterFailedAttemptAsync(usuario, request, "Usuario o contrasena incorrectos.", cancellationToken);
            return UseCaseResult<LoginResultDto>.Fail(
                SeguridadErrorCodes.InvalidCredentials,
                "Usuario o contrasena incorrectos.");
        }

        await usuarioRepository.UpdateLoginSuccessAsync(usuario.Id, now, cancellationToken);

        var sessionToken = sessionTokenService.GenerateToken();
        var expiraEn = now.AddMinutes(loginPolicy.MinutosSesion);
        await sesionRepository.CreateAsync(
            new SesionUsuario
            {
                UsuarioId = usuario.Id,
                TokenHash = sessionTokenService.HashToken(sessionToken),
                IpOrigen = request.Ip,
                UserAgent = request.UserAgent,
                InicioEn = now,
                ExpiraEn = expiraEn,
                Activa = true
            },
            cancellationToken);

        await loginAttemptRepository.RegisterAsync(
            new IntentoLogin
            {
                UsuarioLogin = normalizedUserName,
                UsuarioId = usuario.Id,
                FueExitoso = true,
                IpOrigen = request.Ip,
                Mensaje = "Login exitoso."
            },
            cancellationToken);

        await auditoriaSeguridadRepository.RegisterAsync(
            new AuditoriaSeguridadEvent
            {
                UsuarioAfectadoId = usuario.Id,
                UsuarioAccionId = usuario.Id,
                Evento = SeguridadEventCodes.LoginExitoso,
                Descripcion = "Inicio de sesion correcto.",
                IpOrigen = request.Ip
            },
            cancellationToken);

        return UseCaseResult<LoginResultDto>.Ok(
            new LoginResultDto(
                usuario.Id,
                usuario.UserName,
                usuario.NombreCompleto,
                usuario.RolCodigo ?? string.Empty,
                usuario.RolNombre ?? string.Empty,
                usuario.DebeCambiarPassword,
                sessionToken,
                expiraEn),
            "Login exitoso.");
    }

    private async Task RegisterFailedAttemptAsync(
        Usuario usuario,
        LoginRequestDto request,
        string message,
        CancellationToken cancellationToken)
    {
        await loginAttemptRepository.RegisterAsync(
            new IntentoLogin
            {
                UsuarioLogin = usuario.UserName,
                UsuarioId = usuario.Id,
                FueExitoso = false,
                IpOrigen = request.Ip,
                Mensaje = message
            },
            cancellationToken);

        await auditoriaSeguridadRepository.RegisterAsync(
            new AuditoriaSeguridadEvent
            {
                UsuarioAfectadoId = usuario.Id,
                UsuarioAccionId = usuario.Id,
                Evento = SeguridadEventCodes.LoginFallido,
                Descripcion = message,
                IpOrigen = request.Ip
            },
            cancellationToken);
    }
}
