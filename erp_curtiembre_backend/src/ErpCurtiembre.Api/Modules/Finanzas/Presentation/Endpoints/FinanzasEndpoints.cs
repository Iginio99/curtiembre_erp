using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Activos;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Costos;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Depreciaciones;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Indirectos;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.ManoObra;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Periodos;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Pricing;
using ErpCurtiembre.Modules.Finanzas.Application.UseCases.Reportes;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;

namespace ErpCurtiembre.Modules.Finanzas.Presentation.Endpoints;

public static class FinanzasEndpoints
{
    public static IEndpointRouteBuilder MapFinanzasEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/finanzas").WithTags("Finanzas");

        group.MapGet("/health", () => Results.Ok(new
        {
            module = "Finanzas",
            status = "ready"
        }));

        var periodos = group.MapGroup("/periodos");
        periodos.MapGet("/", async (
            HttpRequest request,
            int? anio,
            int? mes,
            string? estado,
            ValidateSessionUseCase validateSessionUseCase,
            PeriodoCostoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(new PeriodoCostoFiltersDto(anio, mes, estado), cancellationToken));
        });

        periodos.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            PeriodoCostoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        periodos.MapPost("/", async (
            HttpRequest request,
            CreatePeriodoCostoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            PeriodoCostoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.CreateAsync(body, cancellationToken));
        });

        periodos.MapPost("/{id:long}/cerrar", async (
            HttpRequest request,
            long id,
            ClosePeriodoCostoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            PeriodoCostoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null || authorization.Session is null)
            {
                return authorization.Failure!;
            }

            return FinanzasEndpointResults.From(
                await service.CloseAsync(id, authorization.Session.UsuarioId, body, cancellationToken));
        });

        var indirectos = group.MapGroup("/indirectos");
        indirectos.MapGet("/", async (
            HttpRequest request,
            long? periodoCostoId,
            string? tipoCosto,
            string? texto,
            ValidateSessionUseCase validateSessionUseCase,
            CostoIndirectoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new CostoIndirectoFiltersDto(periodoCostoId, tipoCosto, texto),
                cancellationToken));
        });

        indirectos.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CostoIndirectoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        indirectos.MapPost("/", async (
            HttpRequest request,
            CreateCostoIndirectoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CostoIndirectoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null || authorization.Session is null)
            {
                return authorization.Failure!;
            }

            return FinanzasEndpointResults.From(
                await service.CreateAsync(authorization.Session.UsuarioId, body, cancellationToken));
        });

        var manoObra = group.MapGroup("/mano-obra");
        manoObra.MapGet("/", async (
            HttpRequest request,
            long? ordenProduccionId,
            long? ordenProcesoId,
            ValidateSessionUseCase validateSessionUseCase,
            ManoObraDirectaService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new ManoObraDirectaFiltersDto(ordenProduccionId, ordenProcesoId),
                cancellationToken));
        });

        manoObra.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            ManoObraDirectaService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        manoObra.MapPost("/", async (
            HttpRequest request,
            CreateManoObraDirectaRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            ManoObraDirectaService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null || authorization.Session is null)
            {
                return authorization.Failure!;
            }

            return FinanzasEndpointResults.From(
                await service.CreateAsync(authorization.Session.UsuarioId, body, cancellationToken));
        });

        var activos = group.MapGroup("/activos");
        activos.MapGet("/", async (
            HttpRequest request,
            string? texto,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            ActivoDepreciableService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(new ActivoDepreciableFiltersDto(texto, activo), cancellationToken));
        });

        activos.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            ActivoDepreciableService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        activos.MapPost("/", async (
            HttpRequest request,
            CreateActivoDepreciableRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            ActivoDepreciableService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.CreateAsync(body, cancellationToken));
        });

        activos.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateActivoDepreciableRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            ActivoDepreciableService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.UpdateAsync(id, body, cancellationToken));
        });

        var depreciaciones = group.MapGroup("/depreciaciones");
        depreciaciones.MapGet("/", async (
            HttpRequest request,
            long? periodoCostoId,
            long? activoDepreciableId,
            ValidateSessionUseCase validateSessionUseCase,
            DepreciacionPeriodoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new DepreciacionPeriodoFiltersDto(periodoCostoId, activoDepreciableId),
                cancellationToken));
        });

        depreciaciones.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            DepreciacionPeriodoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        periodos.MapPost("/{id:long}/calcular-depreciacion", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            DepreciacionPeriodoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.CalculateForPeriodAsync(id, cancellationToken));
        });

        var costos = group.MapGroup("/costos");
        var costosProceso = costos.MapGroup("/procesos");
        costosProceso.MapGet("/", async (
            HttpRequest request,
            long? ordenProduccionId,
            long? ordenProcesoId,
            ValidateSessionUseCase validateSessionUseCase,
            CostoProcesoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new CostoProcesoFiltersDto(ordenProduccionId, ordenProcesoId),
                cancellationToken));
        });

        costosProceso.MapGet("/{ordenProcesoId:long}", async (
            HttpRequest request,
            long ordenProcesoId,
            ValidateSessionUseCase validateSessionUseCase,
            CostoProcesoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByOrderProcessIdAsync(ordenProcesoId, cancellationToken));
        });

        costosProceso.MapPost("/calcular", async (
            HttpRequest request,
            CalculoCostoProcesoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CostoProcesoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.CalculateAsync(body, cancellationToken));
        });

        var costosOrdenes = costos.MapGroup("/ordenes");
        costosOrdenes.MapGet("/", async (
            HttpRequest request,
            long? ordenProduccionId,
            long? periodoCostoId,
            string? estado,
            ValidateSessionUseCase validateSessionUseCase,
            CostoOrdenService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new CostoOrdenFiltersDto(ordenProduccionId, periodoCostoId, estado),
                cancellationToken));
        });

        costosOrdenes.MapGet("/{ordenProduccionId:long}", async (
            HttpRequest request,
            long ordenProduccionId,
            ValidateSessionUseCase validateSessionUseCase,
            CostoOrdenService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByOrderIdAsync(ordenProduccionId, cancellationToken));
        });

        costosOrdenes.MapPost("/{ordenProduccionId:long}/calcular-estimado", async (
            HttpRequest request,
            long ordenProduccionId,
            ValidateSessionUseCase validateSessionUseCase,
            CostoOrdenService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null || authorization.Session is null)
            {
                return authorization.Failure!;
            }

            return FinanzasEndpointResults.From(
                await service.CalculateEstimatedAsync(ordenProduccionId, authorization.Session.UsuarioId, cancellationToken));
        });

        costosOrdenes.MapPost("/{ordenProduccionId:long}/calcular-real", async (
            HttpRequest request,
            long ordenProduccionId,
            ValidateSessionUseCase validateSessionUseCase,
            CostoOrdenService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null || authorization.Session is null)
            {
                return authorization.Failure!;
            }

            return FinanzasEndpointResults.From(
                await service.CalculateRealAsync(ordenProduccionId, authorization.Session.UsuarioId, cancellationToken));
        });

        costosOrdenes.MapPost("/{ordenProduccionId:long}/cerrar", async (
            HttpRequest request,
            long ordenProduccionId,
            ValidateSessionUseCase validateSessionUseCase,
            CostoOrdenService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null || authorization.Session is null)
            {
                return authorization.Failure!;
            }

            return FinanzasEndpointResults.From(
                await service.CloseAsync(ordenProduccionId, authorization.Session.UsuarioId, cancellationToken));
        });

        var precios = group.MapGroup("/precios");
        precios.MapGet("/{ordenProduccionId:long}", async (
            HttpRequest request,
            long ordenProduccionId,
            ValidateSessionUseCase validateSessionUseCase,
            PrecioSugeridoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByOrderIdAsync(ordenProduccionId, cancellationToken));
        });

        precios.MapPost("/{ordenProduccionId:long}/calcular", async (
            HttpRequest request,
            long ordenProduccionId,
            CalcularPrecioSugeridoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            PrecioSugeridoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.CalculateAsync(ordenProduccionId, body, cancellationToken));
        });

        var rentabilidad = group.MapGroup("/rentabilidad");
        rentabilidad.MapGet("/{ordenProduccionId:long}", async (
            HttpRequest request,
            long ordenProduccionId,
            ValidateSessionUseCase validateSessionUseCase,
            RentabilidadOrdenService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.GetByOrderIdAsync(ordenProduccionId, cancellationToken));
        });

        rentabilidad.MapPost("/{ordenProduccionId:long}/calcular", async (
            HttpRequest request,
            long ordenProduccionId,
            CalcularRentabilidadRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            RentabilidadOrdenService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return FinanzasEndpointResults.From(await service.CalculateAsync(ordenProduccionId, body, cancellationToken));
        });

        var reportes = group.MapGroup("/reportes");
        reportes.MapGet("/costo-orden", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            FinanzasReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(request, validateSessionUseCase, cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListCostoOrdenAsync(cancellationToken));
        });

        reportes.MapGet("/costo-proceso", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            FinanzasReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(request, validateSessionUseCase, cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListCostoProcesoAsync(cancellationToken));
        });

        reportes.MapGet("/costo-cliente", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            FinanzasReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(request, validateSessionUseCase, cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListCostoClienteAsync(cancellationToken));
        });

        reportes.MapGet("/indirectos-periodo", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            FinanzasReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(request, validateSessionUseCase, cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListIndirectosPeriodoAsync(cancellationToken));
        });

        reportes.MapGet("/rentabilidad", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            FinanzasReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(request, validateSessionUseCase, cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListRentabilidadAsync(cancellationToken));
        });

        reportes.MapGet("/precio-sugerido", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            FinanzasReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await FinanzasEndpointResults.RequireFinanceAccessAsync(request, validateSessionUseCase, cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListPrecioSugeridoAsync(cancellationToken));
        });

        return app;
    }
}
