using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Modules.Seguridad.Domain.Rules;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Seguridad.Application.UseCases.Users;

public sealed class CreateUserUseCase(
    IUsuarioRepository usuarioRepository,
    IRolRepository rolRepository,
    IAreaLookupRepository areaLookupRepository,
    IPasswordHasher passwordHasher,
    ValidateSessionUseCase validateSessionUseCase,
    CheckPermissionUseCase checkPermissionUseCase,
    IAuditoriaSeguridadRepository auditoriaSeguridadRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<UserMutationResultDto>> ExecuteAsync(
        string? sessionToken,
        CreateUserRequestDto request,
        CancellationToken cancellationToken)
    {
        var hasUsers = await usuarioRepository.HasAnyUserAsync(cancellationToken);
        long? actorId = null;

        if (hasUsers)
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
                    "No tienes permiso para crear usuarios.");
            }

            actorId = actorResult.Data.UsuarioId;
        }

        var validation = await ValidateUserRequestAsync(request, null, cancellationToken);
        if (validation.Count > 0)
        {
            return UseCaseResult<UserMutationResultDto>.Fail(
                SeguridadErrorCodes.Validation,
                string.Join(" ", validation));
        }

        var temporaryPassword = string.IsNullOrWhiteSpace(request.PasswordTemporal)
            ? passwordHasher.GenerateTemporaryPassword()
            : request.PasswordTemporal.Trim();

        var passwordErrors = PasswordPolicyRule.Validate(temporaryPassword);
        if (passwordErrors.Count > 0)
        {
            return UseCaseResult<UserMutationResultDto>.Fail(
                SeguridadErrorCodes.Validation,
                string.Join(" ", passwordErrors));
        }

        var usuarioId = await usuarioRepository.CreateAsync(
            new Usuario
            {
                RolId = request.RolId,
                AreaId = request.AreaId,
                Nombres = request.Nombres.Trim(),
                Apellidos = request.Apellidos.Trim(),
                Dni = request.Dni.Trim(),
                UserName = request.UserName.Trim(),
                PasswordHash = passwordHasher.HashPassword(temporaryPassword),
                DebeCambiarPassword = true,
                IntentosFallidos = 0,
                UltimoLoginEn = null,
                BloqueadoHasta = null,
                Activo = true,
                CreadoPorUsuarioId = actorId,
                ActualizadoEn = actorId.HasValue ? dateTimeProvider.Now : null,
                ActualizadoPorUsuarioId = actorId
            },
            cancellationToken);

        var created = await usuarioRepository.FindByIdAsync(usuarioId, cancellationToken);
        if (created is null)
        {
            return UseCaseResult<UserMutationResultDto>.Fail(
                SeguridadErrorCodes.NotFound,
                "No se pudo recuperar el usuario creado.");
        }

        await auditoriaSeguridadRepository.RegisterAsync(
            new AuditoriaSeguridadEvent
            {
                UsuarioAfectadoId = usuarioId,
                UsuarioAccionId = actorId,
                Evento = SeguridadEventCodes.UsuarioCreado,
                Descripcion = $"Usuario creado con username {created.UserName}.",
                IpOrigen = null
            },
            cancellationToken);

        return UseCaseResult<UserMutationResultDto>.Ok(
            new UserMutationResultDto(GetUserDetailUseCase.Map(created), temporaryPassword),
            hasUsers ? "Usuario creado correctamente." : "Usuario inicial creado correctamente.");
    }

    private async Task<IReadOnlyCollection<string>> ValidateUserRequestAsync(
        CreateUserRequestDto request,
        long? excludeUserId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        if (await usuarioRepository.ExistsByDniAsync(request.Dni.Trim(), excludeUserId, cancellationToken))
        {
            errors.Add("El DNI ya existe.");
        }

        if (await usuarioRepository.ExistsByUserNameAsync(request.UserName.Trim(), excludeUserId, cancellationToken))
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
