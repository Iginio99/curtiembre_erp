using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Users;

namespace ErpCurtiembre.Modules.Seguridad.Presentation.Endpoints;

public static class SeguridadEndpoints
{
    public static IEndpointRouteBuilder MapSeguridadEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/seguridad").WithTags("Seguridad");

        group.MapGet("/health", () => Results.Ok(new
        {
            module = "Seguridad",
            status = "ready"
        }));

        var auth = group.MapGroup("/auth");
        auth.MapPost("/login", async (
            LoginRequestDto request,
            HttpContext httpContext,
            LoginUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var response = await useCase.ExecuteAsync(
                request with
                {
                    Ip = httpContext.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = httpContext.Request.Headers.UserAgent.ToString()
                },
                cancellationToken);

            return SeguridadEndpointResults.FromLogin(response);
        });

        auth.MapPost("/logout", async (
            HttpRequest request,
            LogoutUseCase useCase,
            CancellationToken cancellationToken) =>
            SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(
                    SeguridadEndpointResults.GetSessionToken(request),
                    cancellationToken)));

        auth.MapGet("/me", async (
            HttpRequest request,
            ValidateSessionUseCase useCase,
            CancellationToken cancellationToken) =>
            SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(
                    SeguridadEndpointResults.GetSessionToken(request),
                    cancellationToken)));

        auth.MapPost("/change-password", async (
            HttpRequest request,
            ChangePasswordRequestDto body,
            ChangePasswordUseCase useCase,
            CancellationToken cancellationToken) =>
            SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(
                    SeguridadEndpointResults.GetSessionToken(request),
                    body,
                    cancellationToken)));

        var users = group.MapGroup("/usuarios");
        users.MapGet("/", async (
            HttpRequest request,
            string? texto,
            long? rolId,
            long? areaId,
            bool? activo,
            int? page,
            int? pageSize,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ListUsersUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await SeguridadEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                new UserFiltersDto(texto, rolId, areaId, activo ?? true, page ?? 1, pageSize ?? 20),
                cancellationToken));
        });

        users.MapGet("/{usuarioId:long}", async (
            HttpRequest request,
            long usuarioId,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            GetUserDetailUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await SeguridadEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return SeguridadEndpointResults.From(await useCase.ExecuteAsync(usuarioId, cancellationToken));
        });

        users.MapPost("/", async (
            HttpRequest request,
            CreateUserRequestDto body,
            CreateUserUseCase useCase,
            CancellationToken cancellationToken) =>
            SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(
                    SeguridadEndpointResults.GetSessionToken(request),
                    body,
                    cancellationToken)));

        users.MapPut("/{usuarioId:long}", async (
            long usuarioId,
            HttpRequest request,
            UpdateUserRequestDto body,
            UpdateUserUseCase useCase,
            CancellationToken cancellationToken) =>
            SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(
                    SeguridadEndpointResults.GetSessionToken(request),
                    usuarioId,
                    body,
                    cancellationToken)));

        users.MapPost("/{usuarioId:long}/deactivate", async (
            long usuarioId,
            HttpRequest request,
            UserStateChangeRequestDto body,
            DeactivateUserUseCase useCase,
            CancellationToken cancellationToken) =>
            SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(
                    SeguridadEndpointResults.GetSessionToken(request),
                    usuarioId,
                    body.Motivo,
                    cancellationToken)));

        users.MapPost("/{usuarioId:long}/reactivate", async (
            long usuarioId,
            HttpRequest request,
            UserStateChangeRequestDto body,
            ReactivateUserUseCase useCase,
            CancellationToken cancellationToken) =>
            SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(
                    SeguridadEndpointResults.GetSessionToken(request),
                    usuarioId,
                    body.Motivo,
                    cancellationToken)));

        users.MapPost("/{usuarioId:long}/reset-password", async (
            long usuarioId,
            HttpRequest request,
            ResetPasswordRequestDto body,
            ResetPasswordUseCase useCase,
            CancellationToken cancellationToken) =>
            SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(
                    SeguridadEndpointResults.GetSessionToken(request),
                    usuarioId,
                    body,
                    cancellationToken)));

        users.MapGet("/{usuarioId:long}/permisos", async (
            HttpRequest request,
            long usuarioId,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            GetPermissionsByUserUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await SeguridadEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(usuarioId, cancellationToken));
        });

        group.MapGet("/mis-permisos", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            GetPermissionsByUserUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var sessionResult = await validateSessionUseCase.ExecuteAsync(
                SeguridadEndpointResults.GetSessionToken(request),
                cancellationToken);
            if (!sessionResult.Success || sessionResult.Data is null)
            {
                return SeguridadEndpointResults.From(sessionResult);
            }

            return Results.Ok(await useCase.ExecuteAsync(sessionResult.Data.UsuarioId, cancellationToken));
        });

        group.MapGet("/roles", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ListRolesUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await SeguridadEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(cancellationToken));
        });

        group.MapGet("/permisos", async (
            HttpRequest request,
            string? modulo,
            string? accion,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ListPermissionsUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await SeguridadEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                new PermissionFiltersDto(modulo, accion, activo),
                cancellationToken));
        });

        group.MapPost("/check-permission", async (
            HttpRequest request,
            CheckPermissionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var sessionResult = await validateSessionUseCase.ExecuteAsync(
                SeguridadEndpointResults.GetSessionToken(request),
                cancellationToken);
            if (!sessionResult.Success || sessionResult.Data is null)
            {
                return SeguridadEndpointResults.From(sessionResult);
            }

            if (sessionResult.Data.UsuarioId != body.UsuarioId)
            {
                var authorization = await SeguridadEndpointResults.RequireAdminAsync(
                    request,
                    validateSessionUseCase,
                    useCase,
                    cancellationToken);

                if (authorization.Failure is not null)
                {
                    return authorization.Failure;
                }
            }

            return SeguridadEndpointResults.From(
                await useCase.ExecuteAsync(body.UsuarioId, body.PermissionCode, cancellationToken));
        });

        group.MapGet("/auditoria", async (
            HttpRequest request,
            long? usuarioAfectadoId,
            long? usuarioAccionId,
            string? evento,
            int? page,
            int? pageSize,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ListAuditSecurityUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await SeguridadEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                new AuditSecurityFiltersDto(usuarioAfectadoId, usuarioAccionId, evento, page ?? 1, pageSize ?? 50),
                cancellationToken));
        });

        return app;
    }
}
