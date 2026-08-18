using ErpCurtiembre.Modules.Alertas.Application.DTOs;
using ErpCurtiembre.Modules.Alertas.Application.UseCases;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;

namespace ErpCurtiembre.Modules.Alertas.Presentation.Endpoints;

public static class AlertasEndpoints
{
    public static IEndpointRouteBuilder MapAlertasEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/alertas").WithTags("Alertas");

        group.MapGet("/health", () => Results.Ok(new
        {
            module = "Alertas",
            status = "ready"
        }));

        group.MapGet("/activas", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ListarAlertasActivasUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await AlertasEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                authorization.Session!.UsuarioId,
                cancellationToken));
        });

        group.MapGet("/", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ListarAlertasUseCase useCase,
            string? estado,
            string? severidad,
            string? tipoAlerta,
            string? moduloOrigen,
            string? fechaDesde,
            string? fechaHasta,
            CancellationToken cancellationToken) =>
        {
            var authorization = await AlertasEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            if (!TryParseOptionalDateTime(fechaDesde, out var fromDate, out var fromError))
            {
                return Results.BadRequest(new { error = "validation_error", message = fromError });
            }

            if (!TryParseOptionalDateTime(fechaHasta, out var toDate, out var toError))
            {
                return Results.BadRequest(new { error = "validation_error", message = toError });
            }

            return Results.Ok(await useCase.ExecuteAsync(
                authorization.Session!.UsuarioId,
                new AlertaFiltersDto(
                    Normalize(estado),
                    Normalize(severidad),
                    Normalize(tipoAlerta),
                    Normalize(moduloOrigen),
                    fromDate,
                    toDate),
                cancellationToken));
        });

        group.MapGet("/resumen", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ObtenerResumenAlertasUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await AlertasEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                authorization.Session!.UsuarioId,
                cancellationToken));
        });

        group.MapGet("/{id:long}", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ObtenerAlertaDetalleUseCase useCase,
            long id,
            CancellationToken cancellationToken) =>
        {
            var authorization = await AlertasEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            var detail = await useCase.ExecuteAsync(
                authorization.Session!.UsuarioId,
                id,
                cancellationToken);

            return detail is null
                ? Results.NotFound(new { error = "alert_not_found", message = "No encontramos la alerta solicitada." })
                : Results.Ok(detail);
        });

        group.MapGet("/{id:long}/historial", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ListarHistorialAlertaUseCase useCase,
            long id,
            CancellationToken cancellationToken) =>
        {
            var authorization = await AlertasEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                authorization.Session!.UsuarioId,
                id,
                cancellationToken));
        });

        group.MapPost("/{id:long}/marcar-leida", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            MarcarAlertaLeidaUseCase useCase,
            long id,
            CancellationToken cancellationToken) =>
        {
            var authorization = await AlertasEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            var detail = await useCase.ExecuteAsync(
                authorization.Session!.UsuarioId,
                id,
                cancellationToken);

            return detail is null
                ? Results.NotFound(new { error = "alert_not_found", message = "No encontramos la alerta solicitada." })
                : Results.Ok(detail);
        });

        group.MapPost("/{id:long}/cerrar", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            CerrarAlertaUseCase useCase,
            long id,
            CerrarAlertaRequestDto? body,
            CancellationToken cancellationToken) =>
        {
            var authorization = await AlertasEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            var detail = await useCase.ExecuteAsync(
                authorization.Session!.UsuarioId,
                id,
                body?.Comentario,
                cancellationToken);

            return detail is null
                ? Results.NotFound(new { error = "alert_not_found", message = "No encontramos la alerta solicitada." })
                : Results.Ok(detail);
        });

        return app;
    }

    private static string? Normalize(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static bool TryParseOptionalDateTime(
        string? value,
        out DateTime? parsed,
        out string? error)
    {
        parsed = null;
        error = null;

        if (string.IsNullOrWhiteSpace(value))
        {
            return true;
        }

        if (DateTime.TryParse(value, out var dateTime))
        {
            parsed = dateTime;
            return true;
        }

        error = $"No pudimos interpretar la fecha '{value}'.";
        return false;
    }
}
