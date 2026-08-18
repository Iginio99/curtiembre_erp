using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;

namespace ErpCurtiembre.Modules.Finanzas.Presentation.Endpoints;

internal static class FinanzasEndpointResults
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
            FinanzasErrorCodes.Validation => Results.BadRequest(new { error = result.ErrorCode, message = result.Message }),
            FinanzasErrorCodes.SessionRequired => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status401Unauthorized),
            FinanzasErrorCodes.SessionExpired => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status401Unauthorized),
            FinanzasErrorCodes.PermissionDenied => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status403Forbidden),
            FinanzasErrorCodes.NotFound => Results.NotFound(new { error = result.ErrorCode, message = result.Message }),
            FinanzasErrorCodes.Conflict => Results.Conflict(new { error = result.ErrorCode, message = result.Message }),
            _ => Results.Json(new { error = result.ErrorCode, message = result.Message }, statusCode: StatusCodes.Status422UnprocessableEntity)
        };
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

    public static async Task<(SessionInfoDto? Session, IResult? Failure)> RequireFinanceAccessAsync(
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
                    error = sessionResult.ErrorCode ?? FinanzasErrorCodes.SessionRequired,
                    message = sessionResult.Message
                },
                statusCode: StatusCodes.Status401Unauthorized));
        }

        var roleCode = sessionResult.Data.RolCodigo.ToUpperInvariant();
        if (roleCode is not ("ADMIN" or "FINANZAS"))
        {
            return (null, Results.Json(
                new
                {
                    error = FinanzasErrorCodes.PermissionDenied,
                    message = "No tienes permiso para acceder a la informacion financiera."
                },
                statusCode: StatusCodes.Status403Forbidden));
        }

        return (sessionResult.Data, null);
    }

    public static async Task<(SessionInfoDto? Session, IResult? Failure)> RequireFinanceAccessAsync(
        HttpRequest request,
        ValidateSessionUseCase validateSessionUseCase,
        CheckPermissionUseCase checkPermissionUseCase,
        CancellationToken cancellationToken) =>
        await RequireAnyPermissionAsync(
            request,
            validateSessionUseCase,
            checkPermissionUseCase,
            [SeguridadPermissionCodes.FinanzasOperar, SeguridadPermissionCodes.FinanzasReportes],
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
                    error = sessionResult.ErrorCode ?? FinanzasErrorCodes.SessionRequired,
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
                    error = FinanzasErrorCodes.PermissionDenied,
                    message = "No tienes permiso para acceder a la informacion financiera."
                },
                statusCode: StatusCodes.Status403Forbidden));
        }

        return (sessionResult.Data, null);
    }
}
