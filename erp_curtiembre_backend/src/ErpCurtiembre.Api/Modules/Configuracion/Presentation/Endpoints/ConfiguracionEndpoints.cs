using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases.Areas;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases.Formulas;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases.TiposPiel;
using ErpCurtiembre.Modules.Configuracion.Application.UseCases.UnidadesMedida;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Auth;
using ErpCurtiembre.Modules.Seguridad.Application.UseCases.Permissions;

namespace ErpCurtiembre.Modules.Configuracion.Presentation.Endpoints;

public static class ConfiguracionEndpoints
{
    public static IEndpointRouteBuilder MapConfiguracionEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/configuracion").WithTags("Configuracion");

        group.MapGet("/health", () => Results.Ok(new
        {
            module = "Configuracion",
            status = "ready"
        }));

        group.MapGet("/parametros", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            ListarParametrosConfiguracionUseCase useCase,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
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

        var areas = group.MapGroup("/areas");
        areas.MapGet("/", async (
            HttpRequest request,
            string? texto,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AreaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(new AreaFiltersDto(texto, activo), cancellationToken));
        });

        areas.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AreaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        areas.MapPost("/", async (
            HttpRequest request,
            CreateAreaRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AreaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.CreateAsync(body, cancellationToken));
        });

        areas.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateAreaRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AreaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.UpdateAsync(id, body, cancellationToken));
        });

        areas.MapPost("/{id:long}/activar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AreaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.ActivateAsync(id, cancellationToken));
        });

        areas.MapPost("/{id:long}/inactivar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            AreaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.InactivateAsync(id, cancellationToken));
        });

        var unidadesMedida = group.MapGroup("/unidades-medida");
        unidadesMedida.MapGet("/", async (
            HttpRequest request,
            string? texto,
            bool? activo,
            bool? permiteDecimales,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            UnidadMedidaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(
                new UnidadMedidaFiltersDto(texto, activo, permiteDecimales),
                cancellationToken));
        });

        unidadesMedida.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            UnidadMedidaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        unidadesMedida.MapPost("/", async (
            HttpRequest request,
            CreateUnidadMedidaRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            UnidadMedidaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.CreateAsync(body, cancellationToken));
        });

        unidadesMedida.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateUnidadMedidaRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            UnidadMedidaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.UpdateAsync(id, body, cancellationToken));
        });

        unidadesMedida.MapPost("/{id:long}/activar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            UnidadMedidaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.ActivateAsync(id, cancellationToken));
        });

        unidadesMedida.MapPost("/{id:long}/inactivar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            UnidadMedidaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.InactivateAsync(id, cancellationToken));
        });

        var tiposPiel = group.MapGroup("/tipos-piel");
        tiposPiel.MapGet("/", async (
            HttpRequest request,
            string? texto,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            TipoPielCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListAsync(new TipoPielFiltersDto(texto, activo), cancellationToken));
        });

        tiposPiel.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            TipoPielCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        tiposPiel.MapPost("/", async (
            HttpRequest request,
            CreateTipoPielRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            TipoPielCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.CreateAsync(body, cancellationToken));
        });

        tiposPiel.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateTipoPielRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            TipoPielCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.UpdateAsync(id, body, cancellationToken));
        });

        tiposPiel.MapPost("/{id:long}/activar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            TipoPielCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.ActivateAsync(id, cancellationToken));
        });

        tiposPiel.MapPost("/{id:long}/inactivar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            TipoPielCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.InactivateAsync(id, cancellationToken));
        });

        var formulas = group.MapGroup("/formulas");
        formulas.MapGet("/", async (
            HttpRequest request,
            string? texto,
            string? procesoProductivoId,
            bool? activo,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            if (!TryParseOptionalLong(procesoProductivoId, out var procesoProductivoIdValue))
            {
                return Results.BadRequest(new
                {
                    error = "validation_error",
                    message = "El filtro procesoProductivoId no es valido."
                });
            }

            return Results.Ok(await service.ListAsync(
                new FormulaFiltersDto(texto, procesoProductivoIdValue, activo),
                cancellationToken));
        });

        formulas.MapGet("/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.GetByIdAsync(id, cancellationToken));
        });

        formulas.MapPost("/", async (
            HttpRequest request,
            CreateFormulaRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null || authorization.Session is null)
            {
                return authorization.Failure!;
            }

            return ConfiguracionEndpointResults.From(await service.CreateAsync(
                body,
                authorization.Session.UsuarioId,
                cancellationToken));
        });

        formulas.MapPut("/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateFormulaRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.UpdateAsync(id, body, cancellationToken));
        });

        formulas.MapPost("/{id:long}/activar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.ActivateAsync(id, cancellationToken));
        });

        formulas.MapPost("/{id:long}/inactivar", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.InactivateAsync(id, cancellationToken));
        });

        formulas.MapGet("/{formulaId:long}/versiones", async (
            HttpRequest request,
            long formulaId,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListVersionsAsync(formulaId, cancellationToken));
        });

        formulas.MapPost("/{formulaId:long}/versiones", async (
            HttpRequest request,
            long formulaId,
            CreateFormulaVersionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null || authorization.Session is null)
            {
                return authorization.Failure!;
            }

            return ConfiguracionEndpointResults.From(await service.CreateVersionAsync(
                formulaId,
                body,
                authorization.Session.UsuarioId,
                cancellationToken));
        });

        group.MapGet("/formula-versiones/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.GetVersionByIdAsync(id, cancellationToken));
        });

        group.MapPut("/formula-versiones/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateFormulaVersionRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.UpdateVersionAsync(id, body, cancellationToken));
        });

        group.MapPost("/formula-versiones/{id:long}/activar-vigencia", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.ActivateVersionAsync(id, cancellationToken));
        });

        group.MapPost("/formula-versiones/{versionId:long}/detalles", async (
            HttpRequest request,
            long versionId,
            CreateFormulaDetalleRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.CreateDetailAsync(versionId, body, cancellationToken));
        });

        group.MapPut("/formula-detalles/{id:long}", async (
            HttpRequest request,
            long id,
            UpdateFormulaDetalleRequestDto body,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.UpdateDetailAsync(id, body, cancellationToken));
        });

        group.MapDelete("/formula-detalles/{id:long}", async (
            HttpRequest request,
            long id,
            ValidateSessionUseCase validateSessionUseCase,
            CheckPermissionUseCase checkPermissionUseCase,
            FormulaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAdminAsync(
                request,
                validateSessionUseCase,
                checkPermissionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return ConfiguracionEndpointResults.From(await service.DeleteDetailAsync(id, cancellationToken));
        });

        var catalogos = group.MapGroup("/catalogos");
        catalogos.MapGet("/areas/activas", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            AreaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListActiveAsync(cancellationToken));
        });

        catalogos.MapGet("/unidades-medida/activas", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            UnidadMedidaCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListActiveAsync(cancellationToken));
        });

        catalogos.MapGet("/tipos-piel/activos", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            TipoPielCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListActiveAsync(cancellationToken));
        });

        catalogos.MapGet("/procesos-productivos/activos-ordenados", async (
            HttpRequest request,
            ValidateSessionUseCase validateSessionUseCase,
            ProcesoProductivoCatalogService service,
            CancellationToken cancellationToken) =>
        {
            var authorization = await ConfiguracionEndpointResults.RequireAuthenticatedAsync(
                request,
                validateSessionUseCase,
                cancellationToken);
            if (authorization.Failure is not null)
            {
                return authorization.Failure;
            }

            return Results.Ok(await service.ListActiveOrderedAsync(cancellationToken));
        });

        return app;
    }

    private static bool TryParseOptionalLong(string? value, out long? parsed)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            parsed = null;
            return true;
        }

        if (long.TryParse(value, out var longValue))
        {
            parsed = longValue;
            return true;
        }

        parsed = null;
        return false;
    }
}
