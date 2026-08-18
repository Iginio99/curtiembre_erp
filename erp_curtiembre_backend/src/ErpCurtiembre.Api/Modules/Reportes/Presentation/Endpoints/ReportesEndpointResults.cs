using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;

namespace ErpCurtiembre.Modules.Reportes.Presentation.Endpoints;

internal static class ReportesEndpointResults
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
                    error = sessionResult.ErrorCode ?? "session_required",
                    message = sessionResult.Message
                },
                statusCode: StatusCodes.Status401Unauthorized));
        }

        return (sessionResult.Data, null);
    }
}
