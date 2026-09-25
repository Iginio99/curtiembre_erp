using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Cierre;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Clientes;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Consumo;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Lotes;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Ordenes;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Procesos;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Reportes;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Solicitudes;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;

namespace ErpCurtiembre.Modules.Produccion.Presentation.Endpoints;

public static class ProduccionEndpoints
{
    public static IEndpointRouteBuilder MapProduccionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/produccion").WithTags("Produccion");

        group.MapGet("/health", () => Results.Ok(new
        {
            module = "Produccion",
            status = "ready"
        }));

        var clientes = group.MapGroup("/clientes");
        clientes.MapGet("/", async (
            HttpRequest request,
            string? texto,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ClienteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(new ClienteFiltersDto(texto, activo), cancellationToken));
        });

        clientes.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ClienteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        clientes.MapPost("/", async (
            HttpRequest request,
            CreateClienteRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ClienteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.CreateAsync(body, cancellationToken));
        });

        clientes.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateClienteRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ClienteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.UpdateAsync(id, body, cancellationToken));
        });

        clientes.MapPost("/{id:long}/activar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ClienteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.ActivateAsync(id, cancellationToken));
        });

        clientes.MapPost("/{id:long}/inactivar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ClienteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.InactivateAsync(id, cancellationToken));
        });

        var lotes = group.MapGroup("/lotes");
        lotes.MapGet("/", async (
            HttpRequest request,
            string? texto,
            long? clienteId,
            long? tipoPielId,
            string? estado,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            LoteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new LoteFiltersDto(texto, clienteId, tipoPielId, estado),
                cancellationToken));
        });

        lotes.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            LoteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        lotes.MapPost("/", async (
            HttpRequest request,
            CreateLoteRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            LoteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(
                await service.CreateAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        lotes.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateLoteRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            LoteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.UpdateAsync(id, body, cancellationToken));
        });

        lotes.MapGet("/{id:long}/disponibilidad", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            LoteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.GetAvailabilityAsync(id, cancellationToken));
        });

        var ordenes = group.MapGroup("/ordenes");
        ordenes.MapGet("/", async (
            HttpRequest request,
            string? texto,
            long? clienteId,
            long? loteId,
            string? estado,
            ValidateSessionUseCase validateSessionUseCase,
            OrdenProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new OrdenProduccionFiltersDto(texto, clienteId, loteId, estado),
                cancellationToken));
        });

        ordenes.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            OrdenProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        ordenes.MapPost("/", async (
            HttpRequest request,
            CreateOrdenProduccionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            OrdenProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(
                await service.CreateAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        ordenes.MapPost("/{id:long}/iniciar", async (
            HttpRequest request,
            long id,
            StartOrdenProduccionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            OrdenProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(
                await service.StartAsync(id, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        ordenes.MapPost("/{id:long}/anular", async (
            HttpRequest request,
            long id,
            CancelOrdenProduccionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            OrdenProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(
                await service.CancelAsync(id, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        ordenes.MapGet("/{ordenId:long}/procesos", async (
            HttpRequest request,
            long ordenId,
            ValidateSessionUseCase validateSessionUseCase,
            OrdenProcesoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListByOrderAsync(ordenId, cancellationToken));
        });

        ordenes.MapPost("/{ordenId:long}/solicitar-consumo", async (
            HttpRequest request,
            long ordenId,
            SolicitarConsumoProduccionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ConsumoProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAnyPermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                [SeguridadPermissionCodes.UsuariosAdmin, SeguridadPermissionCodes.InventarioOperaciones],
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(
                await service.RequestConsumptionAsync(ordenId, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        ordenes.MapGet("/{ordenId:long}/consumo-real", async (
            HttpRequest request,
            long ordenId,
            ValidateSessionUseCase validateSessionUseCase,
            ConsumoProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListRealAsync(ordenId, cancellationToken));
        });

        ordenes.MapGet("/{ordenId:long}/desviaciones", async (
            HttpRequest request,
            long ordenId,
            ValidateSessionUseCase validateSessionUseCase,
            ConsumoProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListDeviationsAsync(ordenId, cancellationToken));
        });

        ordenes.MapPost("/{ordenId:long}/procesos/{procesoId:long}/solicitudes-insumos", async (
            HttpRequest request,
            long ordenId,
            long procesoId,
            CrearSolicitudInsumoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            SolicitudInsumoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.CreateAsync(
                ordenId,
                procesoId,
                body,
                authorization.Session!.UsuarioId,
                cancellationToken));
        });

        var solicitudesInsumos = group.MapGroup("/solicitudes-insumos");
        solicitudesInsumos.MapGet("/", async (
            HttpRequest request,
            string? estado,
            ValidateSessionUseCase validateSessionUseCase,
            SolicitudInsumoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(estado, cancellationToken));
        });

        solicitudesInsumos.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            SolicitudInsumoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        solicitudesInsumos.MapPost("/{id:long}/entregar", async (
            HttpRequest request,
            long id,
            EntregarSolicitudInsumoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            SolicitudInsumoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAnyPermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                [SeguridadPermissionCodes.UsuariosAdmin, SeguridadPermissionCodes.InventarioOperaciones],
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.DeliverAsync(
                id,
                body,
                authorization.Session!.UsuarioId,
                cancellationToken));
        });

        var procesos = group.MapGroup("/procesos");
        procesos.MapPost("/{id:long}/iniciar", async (
            HttpRequest request,
            long id,
            StartOrdenProcesoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            OrdenProcesoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.StartAsync(id, body, cancellationToken));
        });

        procesos.MapPost("/{id:long}/finalizar", async (
            HttpRequest request,
            long id,
            FinishOrdenProcesoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            OrdenProcesoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.FinishAsync(id, body, cancellationToken));
        });

        procesos.MapPost("/{id:long}/ejecutar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            OrdenProcesoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(request, validateSessionUseCase, cancellationToken);
            if (authorization.Failure is not null) return authorization.Failure;
            return ProduccionEndpointResults.From(await service.ExecuteAsync(id, cancellationToken));
        });

        procesos.MapPut("/{id:long}/observacion", async (
            HttpRequest request,
            long id,
            UpdateOrdenProcesoObservacionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            OrdenProcesoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.UpdateObservationAsync(id, body, cancellationToken));
        });

        procesos.MapPost("/{id:long}/mermas", async (
            HttpRequest request,
            long id,
            RegistrarMermaProcesoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CierreProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(
                await service.RegisterMermaAsync(id, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        ordenes.MapPost("/{ordenId:long}/calidad-final", async (
            HttpRequest request,
            long ordenId,
            RegistrarCalidadFinalRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CierreProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(
                await service.RegisterFinalQualityAsync(ordenId, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        ordenes.MapGet("/{ordenId:long}/producto-terminado", async (
            HttpRequest request,
            long ordenId,
            ValidateSessionUseCase validateSessionUseCase,
            CierreProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(await service.GetProductoTerminadoByOrderAsync(ordenId, cancellationToken));
        });

        ordenes.MapPost("/{ordenId:long}/finalizar", async (
            HttpRequest request,
            long ordenId,
            FinalizarOrdenProduccionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CierreProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ProduccionEndpointResults.From(
                await service.FinalizeOrderAsync(ordenId, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        group.MapGet("/productos-terminados", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            CierreProduccionService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListProductosTerminadosAsync(cancellationToken));
        });

        var reportes = group.MapGroup("/reportes");
        reportes.MapGet("/ordenes-activas", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ProduccionReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListActiveOrdersAsync(cancellationToken));
        });

        reportes.MapGet("/ordenes-cliente", async (
            HttpRequest request,
            long? clienteId,
            string? estado,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            ProduccionReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListOrdersByClientAsync(
                new(clienteId, estado, fechaDesde, fechaHasta),
                cancellationToken));
        });

        reportes.MapGet("/consumo-proceso", async (
            HttpRequest request,
            long? ordenProduccionId,
            long? ordenProcesoId,
            ValidateSessionUseCase validateSessionUseCase,
            ProduccionReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListConsumptionByProcessAsync(
                new(ordenProduccionId, ordenProcesoId),
                cancellationToken));
        });

        reportes.MapGet("/merma", async (
            HttpRequest request,
            long? ordenProduccionId,
            long? ordenProcesoId,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            ProduccionReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListMermaAsync(
                new(ordenProduccionId, ordenProcesoId, fechaDesde, fechaHasta),
                cancellationToken));
        });

        reportes.MapGet("/tiempos-proceso", async (
            HttpRequest request,
            long? ordenProduccionId,
            long? ordenProcesoId,
            string? estado,
            ValidateSessionUseCase validateSessionUseCase,
            ProduccionReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListProcessTimesAsync(
                new(ordenProduccionId, ordenProcesoId, estado),
                cancellationToken));
        });

        reportes.MapGet("/costos-orden", async (
            HttpRequest request,
            long? ordenProduccionId,
            ValidateSessionUseCase validateSessionUseCase,
            ProduccionReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListCostsByOrderAsync(
                new(ordenProduccionId),
                cancellationToken));
        });

        reportes.MapGet("/costos-proceso", async (
            HttpRequest request,
            long? ordenProduccionId,
            ValidateSessionUseCase validateSessionUseCase,
            ProduccionReportesService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListCostsByProcessAsync(
                new(ordenProduccionId),
                cancellationToken));
        });

        var catalogos = group.MapGroup("/catalogos");
        catalogos.MapGet("/clientes/activos", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ClienteCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ProduccionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListActiveAsync(cancellationToken));
        });

        return app;
    }
}
