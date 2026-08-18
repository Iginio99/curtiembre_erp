using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Ajustes;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Compras;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Entradas;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Insumos;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.InventarioFisico;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Kardex;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Proveedores;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Salidas;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Stock;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;
using ErpCurtiembre.Modules.Seguridad.Domain.Constants;

namespace ErpCurtiembre.Modules.Inventario.Presentation.Endpoints;

public static class InventarioEndpoints
{
    public static IEndpointRouteBuilder MapInventarioEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/inventario").WithTags("Inventario");

        group.MapGet("/health", () => Results.Ok(new
        {
            module = "Inventario",
            status = "ready"
        }));

        var insumos = group.MapGroup("/insumos");
        insumos.MapGet("/", async (
            HttpRequest request,
            string? texto,
            string? tipoBien,
            long? unidadMedidaId,
            bool? activo,
            bool? stockBajo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InsumoCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new InsumoFiltersDto(texto, tipoBien, unidadMedidaId, activo, stockBajo),
                cancellationToken));
        });

        insumos.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InsumoCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        insumos.MapPost("/", async (
            HttpRequest request,
            CreateInsumoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InsumoCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.CreateAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        insumos.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateInsumoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InsumoCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.UpdateAsync(id, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        insumos.MapPost("/{id:long}/activar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InsumoCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.ActivateAsync(id, authorization.Session!.UsuarioId, cancellationToken));
        });

        insumos.MapPost("/{id:long}/inactivar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InsumoCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.InactivateAsync(id, authorization.Session!.UsuarioId, cancellationToken));
        });

        var proveedores = group.MapGroup("/proveedores");
        proveedores.MapGet("/", async (
            HttpRequest request,
            string? texto,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ProveedorCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(new ProveedorFiltersDto(texto, activo), cancellationToken));
        });

        proveedores.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ProveedorCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        proveedores.MapPost("/", async (
            HttpRequest request,
            CreateProveedorRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ProveedorCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.CreateAsync(body, cancellationToken));
        });

        proveedores.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateProveedorRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ProveedorCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.UpdateAsync(id, body, cancellationToken));
        });

        proveedores.MapPost("/{id:long}/activar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ProveedorCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.ActivateAsync(id, cancellationToken));
        });

        proveedores.MapPost("/{id:long}/inactivar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ProveedorCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioMaestros,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.InactivateAsync(id, cancellationToken));
        });

        var compras = group.MapGroup("/compras");
        compras.MapGet("/", async (
            HttpRequest request,
            string? texto,
            long? proveedorId,
            string? estado,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            OrdenCompraService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new OrdenCompraFiltersDto(texto, proveedorId, estado, fechaDesde, fechaHasta),
                cancellationToken));
        });

        compras.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            OrdenCompraService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        compras.MapPost("/", async (
            HttpRequest request,
            CreateOrdenCompraRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            OrdenCompraService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.CreateAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        compras.MapPost("/{id:long}/aprobar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            OrdenCompraService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.ComprasAprobar,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.ApproveAsync(id, authorization.Session!.UsuarioId, cancellationToken));
        });

        compras.MapPost("/{id:long}/rechazar", async (
            HttpRequest request,
            long id,
            OrdenCompraDecisionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            OrdenCompraService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.ComprasAprobar,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RejectAsync(id, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        compras.MapPost("/{id:long}/anular", async (
            HttpRequest request,
            long id,
            OrdenCompraDecisionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            OrdenCompraService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.ComprasAnular,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.CancelAsync(id, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        var entradas = group.MapGroup("/entradas");
        entradas.MapPost("/stock-inicial", async (
            HttpRequest request,
            RegistrarStockInicialRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            StockInitialService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        entradas.MapPost("/desde-compra", async (
            HttpRequest request,
            RegistrarEntradaCompraRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            PurchaseEntryService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        entradas.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            IEntradaInventarioRepository repository,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            var entry = await repository.FindByIdAsync(id, cancellationToken);
            if (entry is null)
            {
                return Results.NotFound(new { error = InventarioErrorCodes.NotFound, message = "No se encontro la entrada de inventario." });
            }

            var details = await repository.ListDetailsAsync(id, cancellationToken);
            return Results.Ok(new EntradaInventarioDetailDto(
                entry.Id,
                entry.Codigo,
                entry.TipoEntrada,
                entry.FechaEntrada,
                entry.DocumentoSoporte,
                entry.Observacion,
                entry.Estado,
                entry.CreadoPorUsuarioId,
                entry.CreadoEn,
                details.Select(detail => new EntradaInventarioDetalleDto(
                    detail.Id,
                    detail.InsumoId,
                    detail.InsumoCodigo,
                    detail.InsumoNombre,
                    detail.Cantidad,
                    detail.CostoUnitario,
                    detail.CostoTotal,
                    detail.StockActual,
                    detail.UnidadMedidaCodigo,
                    detail.UnidadMedidaNombre,
                    detail.Observacion)).ToArray()));
        });

        var stock = group.MapGroup("/stock");
        stock.MapGet("/", async (
            HttpRequest request,
            string? texto,
            string? tipoBien,
            bool? stockBajo,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            StockQueryService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioStock,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new StockFiltersDto(texto, tipoBien, stockBajo, activo),
                cancellationToken));
        });

        stock.MapGet("/bajo", async (
            HttpRequest request,
            string? texto,
            string? tipoBien,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            StockQueryService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioStock,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new StockFiltersDto(texto, tipoBien, true, activo),
                cancellationToken));
        });

        stock.MapGet("/{insumoId:long}", async (
            HttpRequest request,
            long insumoId,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            StockQueryService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioStock,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.GetByInsumoIdAsync(insumoId, cancellationToken));
        });

        var kardex = group.MapGroup("/kardex");
        kardex.MapGet("/", async (
            HttpRequest request,
            long? insumoId,
            string? tipoMovimiento,
            string? documentoTipo,
            long? usuarioResponsableId,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            KardexQueryService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioKardex,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new KardexFiltersDto(
                    insumoId,
                    tipoMovimiento,
                    documentoTipo,
                    usuarioResponsableId,
                    fechaDesde,
                    fechaHasta),
                cancellationToken));
        });

        kardex.MapGet("/{insumoId:long}", async (
            HttpRequest request,
            long insumoId,
            string? tipoMovimiento,
            string? documentoTipo,
            long? usuarioResponsableId,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            KardexQueryService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioKardex,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListByInsumoAsync(
                insumoId,
                new KardexFiltersDto(
                    null,
                    tipoMovimiento,
                    documentoTipo,
                    usuarioResponsableId,
                    fechaDesde,
                    fechaHasta),
                cancellationToken));
        });

        var salidas = group.MapGroup("/salidas");
        salidas.MapGet("/", async (
            HttpRequest request,
            string? texto,
            string? tipoSalida,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            SalidaInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new SalidaInventarioFiltersDto(texto, tipoSalida, fechaDesde, fechaHasta),
                cancellationToken));
        });

        salidas.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            SalidaInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        salidas.MapPost("/general", async (
            HttpRequest request,
            RegistrarSalidaGeneralRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            SalidaInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterGeneralAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        salidas.MapPost("/proceso", async (
            HttpRequest request,
            RegistrarSalidaProcesoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            SalidaInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterProcessAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        salidas.MapPost("/devolucion-proveedor", async (
            HttpRequest request,
            RegistrarDevolucionProveedorRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            SalidaInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterSupplierReturnAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        salidas.MapPost("/ajuste-negativo", async (
            HttpRequest request,
            RegistrarAjusteNegativoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            SalidaInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterNegativeAdjustmentAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        var ajustes = group.MapGroup("/ajustes");
        ajustes.MapGet("/", async (
            HttpRequest request,
            string? texto,
            string? tipoAjuste,
            DateTime? fechaDesde,
            DateTime? fechaHasta,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AjusteInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new AjusteInventarioFiltersDto(texto, tipoAjuste, fechaDesde, fechaHasta),
                cancellationToken));
        });

        ajustes.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AjusteInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        ajustes.MapPost("/positivo", async (
            HttpRequest request,
            RegistrarAjusteInventarioRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AjusteInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterPositiveAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        ajustes.MapPost("/negativo", async (
            HttpRequest request,
            RegistrarAjusteInventarioRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AjusteInventarioService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterNegativeAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        var fisico = group.MapGroup("/fisico");
        fisico.MapGet("/", async (
            HttpRequest request,
            int? periodoAnio,
            int? periodoMes,
            string? estado,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InventarioFisicoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new InventarioFisicoFiltersDto(periodoAnio, periodoMes, estado),
                cancellationToken));
        });

        fisico.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InventarioFisicoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        fisico.MapPost("/", async (
            HttpRequest request,
            CrearInventarioFisicoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InventarioFisicoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.CreateAsync(body, authorization.Session!.UsuarioId, cancellationToken));
        });

        fisico.MapPost("/{id:long}/detalle", async (
            HttpRequest request,
            long id,
            RegistrarConteoInventarioFisicoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InventarioFisicoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.RegisterCountsAsync(id, body, cancellationToken));
        });

        fisico.MapPost("/{id:long}/cerrar", async (
            HttpRequest request,
            long id,
            CerrarInventarioFisicoRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            InventarioFisicoService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequirePermissionAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                SeguridadPermissionCodes.InventarioOperaciones,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return InventarioEndpointResults.From(
                await service.CloseAsync(id, body, authorization.Session!.UsuarioId, cancellationToken));
        });

        var catalogos = group.MapGroup("/catalogos");
        catalogos.MapGet("/insumos/activos", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            InsumoCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListActiveAsync(cancellationToken));
        });

        catalogos.MapGet("/proveedores/activos", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ProveedorCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await InventarioEndpointResults.RequireAuthenticatedAsync(
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
