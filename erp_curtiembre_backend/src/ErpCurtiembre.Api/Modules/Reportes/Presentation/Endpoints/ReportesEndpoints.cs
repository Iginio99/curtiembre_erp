using ErpCurtiembre.Modules.Reportes.Application.UseCases;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;

namespace ErpCurtiembre.Modules.Reportes.Presentation.Endpoints;

public static class ReportesEndpoints
{
    public static IEndpointRouteBuilder MapReportesEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/reportes").WithTags("Reportes");

        group.MapGet("/health", () => Results.Ok(new
        {
            module = "Reportes",
            status = "ready"
        }));

        group.MapGet("/dashboard-kpis", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ObtenerDashboardKpiUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ReportesEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(cancellationToken));
        });

        group.MapGet("/stock-bajo", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ListarStockBajoReporteUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ReportesEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(cancellationToken));
        });

        group.MapGet("/stock-actual", async (
            HttpRequest request,
            string? texto,
            string? tipoBien,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            ListarStockActualReporteUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ReportesEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                new(texto, tipoBien, activo),
                cancellationToken));
        });

        group.MapGet("/kardex", async (
            HttpRequest request,
            long? insumoId,
            string? tipoMovimiento,
            string? documentoTipo,
            string? texto,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            ListarKardexReporteUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ReportesEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                new(insumoId, tipoMovimiento, documentoTipo, texto, fechaDesde, fechaHasta),
                cancellationToken));
        });

        group.MapGet("/compras-proveedor", async (
            HttpRequest request,
            long? proveedorId,
            string? estado,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            ListarComprasProveedorReporteUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ReportesEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                new(proveedorId, estado, fechaDesde, fechaHasta),
                cancellationToken));
        });

        group.MapGet("/consumo-proceso", async (
            HttpRequest request,
            long? ordenProduccionId,
            long? ordenProcesoId,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            ListarConsumoProcesoReporteUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ReportesEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await useCase.ExecuteAsync(
                new(ordenProduccionId, ordenProcesoId, fechaDesde, fechaHasta),
                cancellationToken));
        });

        return app;
    }
}
