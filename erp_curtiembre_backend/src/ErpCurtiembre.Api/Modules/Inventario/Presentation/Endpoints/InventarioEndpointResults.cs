using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;

namespace ErpCurtiembre.Modules.Inventario.Presentation.Endpoints;

internal static class InventarioEndpointResults
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
            InventarioErrorCodes.Validation => Results.BadRequest(new { error = result.ErrorCode, message = result.Message }),
            InventarioErrorCodes.SessionRequired => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status401Unauthorized),
            InventarioErrorCodes.SessionExpired => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status401Unauthorized),
            InventarioErrorCodes.PermissionDenied => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status403Forbidden),
            InventarioErrorCodes.NotFound => Results.NotFound(new { error = result.ErrorCode, message = result.Message }),
            InventarioErrorCodes.Conflict => Results.Conflict(new { error = result.ErrorCode, message = result.Message }),
            _ => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status422UnprocessableEntity)
        };
    }

    public static async Task<(SessionInfoDto? Session, IResult? Failure)> RequireAuthenticatedAsync(
        HttpRequest request,
        ValidateSessionUseCase validateSessionUseCase,
        CancellationToken cancellationToken)
    {
        var sessionResult = await validateSessionUseCase.ExecuteAsync(GetSessionToken(request), cancellationToken);
        if (!sessionResult.Success || sessionResult.Data is null)
        {
            return (null, Results.Json(
                new
                {
                    error = sessionResult.ErrorCode ?? InventarioErrorCodes.SessionRequired,
                    message = sessionResult.Message
                },
                statusCode: StatusCodes.Status401Unauthorized));
        }

        return (sessionResult.Data, null);
    }

    public static async Task<(SessionInfoDto? Session, IResult? Failure)> RequirePermissionAsync(
        HttpRequest request,
        ValidateSessionUseCase validateSessionUseCase,
        CheckPermissionUseCase checkPermissionUseCase,
        string permissionCode,
        CancellationToken cancellationToken) =>
        await RequireAnyPermissionAsync(
            request,
            validateSessionUseCase,
            checkPermissionUseCase,
            [permissionCode],
            cancellationToken);

    public static async Task<(SessionInfoDto? Session, IResult? Failure)> RequireAnyPermissionAsync(
        HttpRequest request,
        ValidateSessionUseCase validateSessionUseCase,
        CheckPermissionUseCase checkPermissionUseCase,
        IReadOnlyCollection<string> permissionCodes,
        CancellationToken cancellationToken)
    {
        var sessionResult = await validateSessionUseCase.ExecuteAsync(GetSessionToken(request), cancellationToken);
        if (!sessionResult.Success || sessionResult.Data is null)
        {
            return (null, Results.Json(
                new
                {
                    error = sessionResult.ErrorCode ?? InventarioErrorCodes.SessionRequired,
                    message = sessionResult.Message
                },
                statusCode: StatusCodes.Status401Unauthorized));
        }

        var allowed = false;
        foreach (var permissionCode in permissionCodes.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            var permissionResult = await checkPermissionUseCase.ExecuteAsync(
                sessionResult.Data.UsuarioId,
                permissionCode,
                cancellationToken);

            if (permissionResult.Success && permissionResult.Data?.Allowed == true)
            {
                allowed = true;
                break;
            }
        }

        if (!allowed)
        {
            return (null, Results.Json(
                new
                {
                    error = InventarioErrorCodes.PermissionDenied,
                    message = "No tienes permiso para ejecutar esta accion."
                },
                statusCode: StatusCodes.Status403Forbidden));
        }

        return (sessionResult.Data, null);
    }
}
