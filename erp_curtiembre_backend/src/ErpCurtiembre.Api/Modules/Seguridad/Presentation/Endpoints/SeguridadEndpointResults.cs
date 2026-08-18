using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;

namespace ErpCurtiembre.Modules.Seguridad.Presentation.Endpoints;

internal static class SeguridadEndpointResults
{
    public static string? GetSessionToken(HttpRequest request)
    {
        if (request.Headers.Authorization.Count > 0)
        {
            var authorization = request.Headers.Authorization.ToString();
            const string bearerPrefix = "Bearer ";
            if (authorization.StartsWith(bearerPrefix, StringComparison.OrdinalIgnoreCase))
            {
                return authorization[bearerPrefix.Length..].Trim();
            }
        }

        if (request.Headers.TryGetValue("X-Session-Token", out var tokenValues))
        {
            return tokenValues.ToString();
        }

        return null;
    }

    public static IResult From<T>(UseCaseResult<T> result)
    {
        if (result.Success)
        {
            return Results.Ok(result.Data);
        }

        return result.ErrorCode switch
        {
            SeguridadErrorCodes.Validation => Results.BadRequest(new { error = result.ErrorCode, message = result.Message }),
            SeguridadErrorCodes.InvalidCredentials => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status401Unauthorized),
            SeguridadErrorCodes.SessionRequired => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status401Unauthorized),
            SeguridadErrorCodes.SessionExpired => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status401Unauthorized),
            SeguridadErrorCodes.PermissionDenied => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status403Forbidden),
            SeguridadErrorCodes.NotFound => Results.NotFound(new { error = result.ErrorCode, message = result.Message }),
            SeguridadErrorCodes.Conflict => Results.Conflict(new { error = result.ErrorCode, message = result.Message }),
            _ => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status422UnprocessableEntity)
        };
    }

    public static IResult FromLogin<T>(UseCaseResult<T> result)
    {
        if (result.Success)
        {
            return Results.Ok(result.Data);
        }

        return result.ErrorCode switch
        {
            SeguridadErrorCodes.InvalidCredentials => Results.Json(
                new
                {
                    error = SeguridadErrorCodes.InvalidCredentials,
                    message = "Usuario o contrasena incorrectos."
                },
                statusCode: StatusCodes.Status401Unauthorized),
            SeguridadErrorCodes.InactiveUser => Results.Json(
                new
                {
                    error = SeguridadErrorCodes.InvalidCredentials,
                    message = "Usuario o contrasena incorrectos."
                },
                statusCode: StatusCodes.Status401Unauthorized),
            SeguridadErrorCodes.UserBlocked => Results.Json(
                new
                {
                    error = SeguridadErrorCodes.InvalidCredentials,
                    message = "Usuario o contrasena incorrectos."
                },
                statusCode: StatusCodes.Status401Unauthorized),
            _ => From(result)
        };
    }

    public static async Task<(SessionInfoDto? Session, IResult? Failure)> RequireAdminAsync(
        HttpRequest request,
        ValidateSessionUseCase validateSessionUseCase,
        CheckPermissionUseCase checkPermissionUseCase,
        CancellationToken cancellationToken)
    {
        var sessionResult = await validateSessionUseCase.ExecuteAsync(GetSessionToken(request), cancellationToken);
        if (!sessionResult.Success || sessionResult.Data is null)
        {
            return (null, From(sessionResult));
        }

        var permissionResult = await checkPermissionUseCase.ExecuteAsync(
            sessionResult.Data.UsuarioId,
            SeguridadPermissionCodes.UsuariosAdmin,
            cancellationToken);

        if (!permissionResult.Success || permissionResult.Data?.Allowed != true)
        {
            return (null, Results.Json(
                new
                {
                    error = SeguridadErrorCodes.PermissionDenied,
                    message = "No tienes permiso para ejecutar esta accion."
                },
                statusCode: StatusCodes.Status403Forbidden));
        }

        return (sessionResult.Data, null);
    }
}
