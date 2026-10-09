using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Cierre;

public sealed class CierreProduccionService(
    IOrdenProduccionRepository ordenProduccionRepository,
    ICierreProduccionRepository cierreProduccionRepository,
    ICalidadProductoLookupRepository calidadProductoLookupRepository,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider,
    ErpCurtiembre.Shared.Persistence.ISqlConnectionFactory connectionFactory)
{
    private static readonly HashSet<string> AllowedQualityCodes = new(StringComparer.OrdinalIgnoreCase)
    {
        "A",
        "B",
        "C"
    };

    public async Task<UseCaseResult<MermaProcesoDto>> RegisterMermaAsync(
        long processId,
        RegistrarMermaProcesoRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var process = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        if (process is null)
        {
            return UseCaseResult<MermaProcesoDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso de la orden.");
        }

        if (process.OrdenEstado == "ANULADA")
        {
            return UseCaseResult<MermaProcesoDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "No se puede registrar merma en una orden anulada.");
        }

        if (request.CantidadPerdida < 0)
        {
            return UseCaseResult<MermaProcesoDto>.Fail(
                ProduccionErrorCodes.Validation,
                "La cantidad perdida no puede ser negativa.");
        }

        var mermaId = await cierreProduccionRepository.RegisterMermaAsync(
            new MermaProceso
            {
                OrdenProduccionId = process.OrdenProduccionId,
                OrdenProcesoId = process.Id,
                CantidadPerdida = decimal.Round(request.CantidadPerdida, 4),
                Motivo = NormalizeNullable(request.Motivo),
                Observacion = NormalizeNullable(request.Observacion),
                RegistradoEn = dateTimeProvider.Now,
                RegistradoPorUsuarioId = actorId
            },
            cancellationToken);

        var created = await cierreProduccionRepository.FindMermaByIdAsync(mermaId, cancellationToken);
        return created is null
            ? UseCaseResult<MermaProcesoDto>.Fail(ProduccionErrorCodes.NotFound, "No se pudo recuperar la merma registrada.")
            : UseCaseResult<MermaProcesoDto>.Ok(MapMerma(created), "Merma registrada correctamente.");
    }

    public async Task<UseCaseResult<ControlCalidadDto>> RegisterFinalQualityAsync(
        long orderId,
        RegistrarCalidadFinalRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        if (await cierreProduccionRepository.FindLatestControlCalidadAsync(orderId, cancellationToken) is not null)
        {
            return UseCaseResult<ControlCalidadDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La orden ya tiene una calidad final registrada. Usa la opcion Editar.");
        }
        var order = await ordenProduccionRepository.FindByIdAsync(orderId, cancellationToken);
        if (order is null)
        {
            return UseCaseResult<ControlCalidadDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la orden de produccion.");
        }

        if (order.Estado == "ANULADA")
        {
            return UseCaseResult<ControlCalidadDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "No se puede registrar calidad final para una orden anulada.");
        }

        var processes = await ordenProduccionRepository.ListProcessesAsync(orderId, cancellationToken);
        if (processes.Count == 0 || processes.Where(x => x.ProcesoCodigo is "REMOJO_PELAMBRE" or "CURTIDO").Any(x => x.Estado != "FINALIZADO"))
        {
            return UseCaseResult<ControlCalidadDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La calidad final solo puede registrarse cuando Remojo-Pelambre y Curtido esten finalizados.");
        }
        using (var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken))
        {
            var pendingProducts = await connection.ExecuteScalarAsync<int>(new CommandDefinition(
                "SELECT CASE WHEN COUNT(1)=0 THEN 1 ELSE SUM(CASE WHEN estado_acabado<>'FINALIZADO' THEN 1 ELSE 0 END) END FROM produccion.orden_producto WHERE orden_produccion_id=@OrderId AND activo=1",
                new { OrderId = orderId }, cancellationToken: cancellationToken));
            if (pendingProducts > 0) return UseCaseResult<ControlCalidadDto>.Fail(ProduccionErrorCodes.Conflict, "Todos los productos deben finalizar Acabado antes de registrar la calidad final.");
        }

        var calidad = await calidadProductoLookupRepository.FindActiveByIdAsync(request.CalidadProductoId, cancellationToken);
        if (calidad is null)
        {
            return UseCaseResult<ControlCalidadDto>.Fail(
                ProduccionErrorCodes.Validation,
                "La calidad seleccionada no existe o se encuentra inactiva.");
        }

        if (!AllowedQualityCodes.Contains(calidad.Codigo))
        {
            return UseCaseResult<ControlCalidadDto>.Fail(
                ProduccionErrorCodes.Validation,
                "La calidad final del MVP solo permite los codigos A, B o C.");
        }

        var cantidades = new[]
        {
            request.CantidadLadosA,
            request.CantidadLadosB,
            request.CantidadLadosC,
            request.CantidadLadosMerma
        };
        if (cantidades.Any(x => x < 0 || x != decimal.Truncate(x)))
        {
            return UseCaseResult<ControlCalidadDto>.Fail(
                ProduccionErrorCodes.Validation,
                "Las cantidades A, B, C y merma deben ser numeros enteros de lados y no pueden ser negativas.");
        }

        var ladosEsperados = order.CantidadPieles * 2m;
        var ladosClasificados = cantidades.Sum();
        if (ladosClasificados != ladosEsperados)
        {
            return UseCaseResult<ControlCalidadDto>.Fail(
                ProduccionErrorCodes.Validation,
                $"La suma de A, B, C y merma debe ser exactamente {ladosEsperados:0.##} lados.");
        }

        var resultado = string.IsNullOrWhiteSpace(request.Resultado) ? "APROBADO" : request.Resultado.Trim().ToUpperInvariant();
        if (resultado is not ("APROBADO" or "OBSERVADO" or "RECHAZADO"))
        {
            return UseCaseResult<ControlCalidadDto>.Fail(
                ProduccionErrorCodes.Validation,
                "El resultado de calidad debe ser APROBADO, OBSERVADO o RECHAZADO.");
        }

        var controlId = await cierreProduccionRepository.RegisterControlCalidadAsync(
            new ControlCalidad
            {
                OrdenProduccionId = orderId,
                CalidadProductoId = calidad.Id,
                CantidadLadosA = request.CantidadLadosA,
                CantidadLadosB = request.CantidadLadosB,
                CantidadLadosC = request.CantidadLadosC,
                CantidadLadosMerma = request.CantidadLadosMerma,
                Resultado = resultado,
                Observacion = NormalizeNullable(request.Observacion),
                EvaluadoEn = dateTimeProvider.Now,
                EvaluadoPorUsuarioId = actorId
            },
            cancellationToken);

        var created = await cierreProduccionRepository.FindControlCalidadByIdAsync(controlId, cancellationToken);
        return created is null
            ? UseCaseResult<ControlCalidadDto>.Fail(ProduccionErrorCodes.NotFound, "No se pudo recuperar el control de calidad registrado.")
            : UseCaseResult<ControlCalidadDto>.Ok(MapQuality(created), "Calidad final registrada correctamente.");
    }

    public async Task<UseCaseResult<ControlCalidadDto>> GetFinalQualityAsync(
        long orderId,
        CancellationToken cancellationToken)
    {
        var quality = await cierreProduccionRepository.FindLatestControlCalidadAsync(orderId, cancellationToken);
        return quality is null
            ? UseCaseResult<ControlCalidadDto>.Fail(ProduccionErrorCodes.NotFound, "La orden aun no tiene calidad final registrada.")
            : UseCaseResult<ControlCalidadDto>.Ok(MapQuality(quality));
    }

    public async Task<UseCaseResult<ControlCalidadDto>> UpdateFinalQualityAsync(
        long orderId,
        RegistrarCalidadFinalRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(orderId, cancellationToken);
        var current = await cierreProduccionRepository.FindLatestControlCalidadAsync(orderId, cancellationToken);
        if (order is null || current is null)
            return UseCaseResult<ControlCalidadDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la calidad final.");
        if (current.ProductoTerminadoId.HasValue)
            return UseCaseResult<ControlCalidadDto>.Fail(ProduccionErrorCodes.Conflict, "No se puede editar despues de generar el producto terminado.");

        var calidad = await calidadProductoLookupRepository.FindActiveByIdAsync(request.CalidadProductoId, cancellationToken);
        if (calidad is null || !AllowedQualityCodes.Contains(calidad.Codigo))
            return UseCaseResult<ControlCalidadDto>.Fail(ProduccionErrorCodes.Validation, "La calidad seleccionada no es valida.");

        var cantidades = new[] { request.CantidadLadosA, request.CantidadLadosB, request.CantidadLadosC, request.CantidadLadosMerma };
        if (cantidades.Any(x => x < 0 || x != decimal.Truncate(x)) || cantidades.Sum() != order.CantidadPieles * 2m)
            return UseCaseResult<ControlCalidadDto>.Fail(ProduccionErrorCodes.Validation, "La distribucion debe coincidir con el total de lados de la orden.");

        var updated = new ControlCalidad
        {
            OrdenProduccionId = orderId,
            CalidadProductoId = calidad.Id,
            CantidadLadosA = request.CantidadLadosA,
            CantidadLadosB = request.CantidadLadosB,
            CantidadLadosC = request.CantidadLadosC,
            CantidadLadosMerma = request.CantidadLadosMerma,
            Resultado = string.IsNullOrWhiteSpace(request.Resultado) ? "APROBADO" : request.Resultado.Trim().ToUpperInvariant(),
            Observacion = NormalizeNullable(request.Observacion),
            EvaluadoEn = dateTimeProvider.Now,
            EvaluadoPorUsuarioId = actorId
        };
        await cierreProduccionRepository.UpdateControlCalidadAsync(current.Id, updated, cancellationToken);
        var saved = await cierreProduccionRepository.FindControlCalidadByIdAsync(current.Id, cancellationToken);
        return UseCaseResult<ControlCalidadDto>.Ok(MapQuality(saved!), "Calidad final actualizada correctamente.");
    }

    public async Task<UseCaseResult<ProductoTerminadoDetailDto>> GetProductoTerminadoByOrderAsync(
        long orderId,
        CancellationToken cancellationToken)
    {
        var product = await cierreProduccionRepository.FindProductoTerminadoByOrderIdAsync(orderId, cancellationToken);
        return product is null
            ? UseCaseResult<ProductoTerminadoDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro producto terminado para la orden.")
            : UseCaseResult<ProductoTerminadoDetailDto>.Ok(MapProduct(product));
    }

    public async Task<IReadOnlyCollection<ProductoTerminadoListItemDto>> ListProductosTerminadosAsync(CancellationToken cancellationToken)
    {
        var items = await cierreProduccionRepository.ListProductosTerminadosAsync(cancellationToken);
        return items.Select(MapProductList).ToArray();
    }

    public async Task<UseCaseResult<ProductoTerminadoDetailDto>> FinalizeOrderAsync(
        long orderId,
        FinalizarOrdenProduccionRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(orderId, cancellationToken);
        if (order is null)
        {
            return UseCaseResult<ProductoTerminadoDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la orden de produccion.");
        }

        if (order.Estado == "ANULADA")
        {
            return UseCaseResult<ProductoTerminadoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "No se puede finalizar una orden anulada.");
        }

        if (order.Estado == "FINALIZADA")
        {
            return UseCaseResult<ProductoTerminadoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La orden ya se encuentra finalizada.");
        }

        var processes = await ordenProduccionRepository.ListProcessesAsync(orderId, cancellationToken);
        if (processes.Count == 0 || processes.Where(x => x.ProcesoCodigo is "REMOJO_PELAMBRE" or "CURTIDO").Any(x => x.Estado != "FINALIZADO"))
        {
            return UseCaseResult<ProductoTerminadoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La orden solo puede finalizarse cuando Remojo-Pelambre y Curtido esten finalizados.");
        }
        using (var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken))
        {
            var pendingProducts = await connection.ExecuteScalarAsync<int>(new CommandDefinition(
                "SELECT CASE WHEN COUNT(1)=0 THEN 1 ELSE SUM(CASE WHEN estado_acabado<>'FINALIZADO' THEN 1 ELSE 0 END) END FROM produccion.orden_producto WHERE orden_produccion_id=@OrderId AND activo=1",
                new { OrderId = orderId }, cancellationToken: cancellationToken));
            if (pendingProducts > 0) return UseCaseResult<ProductoTerminadoDetailDto>.Fail(ProduccionErrorCodes.Conflict, "Todos los productos deben finalizar Acabado antes de cerrar la orden.");
        }

        var latestQuality = await cierreProduccionRepository.FindLatestControlCalidadAsync(orderId, cancellationToken);
        if (latestQuality is null)
        {
            return UseCaseResult<ProductoTerminadoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La orden requiere un control de calidad final antes de finalizarse.");
        }

        if (!string.Equals(latestQuality.Resultado, "APROBADO", StringComparison.OrdinalIgnoreCase))
        {
            return UseCaseResult<ProductoTerminadoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se puede finalizar una orden con control de calidad APROBADO.");
        }


        var cantidadLadosTerminados = latestQuality.CantidadLadosA
            + latestQuality.CantidadLadosB
            + latestQuality.CantidadLadosC;

        if (await cierreProduccionRepository.FindProductoTerminadoByOrderIdAsync(orderId, cancellationToken) is not null)
        {
            return UseCaseResult<ProductoTerminadoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La orden ya tiene un producto terminado generado.");
        }

        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync("PT", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<ProductoTerminadoDetailDto>.Fail(ProduccionErrorCodes.Conflict, exception.Message);
        }

        var productId = await cierreProduccionRepository.FinalizeOrderAsync(
            new FinalizacionProduccion
            {
                OrdenProduccionId = orderId,
                ControlCalidadId = latestQuality.Id,
                CalidadProductoId = latestQuality.CalidadProductoId,
                ProductoTerminadoCodigo = codigo,
                CantidadLados = cantidadLadosTerminados,
                CantidadLadosA = latestQuality.CantidadLadosA,
                CantidadLadosB = latestQuality.CantidadLadosB,
                CantidadLadosC = latestQuality.CantidadLadosC,
                CantidadLadosMerma = latestQuality.CantidadLadosMerma,
                Observacion = NormalizeNullable(request.Observacion),
                ActorId = actorId,
                Timestamp = dateTimeProvider.Now
            },
            cancellationToken);

        var product = await cierreProduccionRepository.FindProductoTerminadoByOrderIdAsync(orderId, cancellationToken);
        return product is null || product.Id != productId
            ? UseCaseResult<ProductoTerminadoDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se pudo recuperar el producto terminado generado.")
            : UseCaseResult<ProductoTerminadoDetailDto>.Ok(MapProduct(product), "Orden finalizada correctamente.");
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static MermaProcesoDto MapMerma(MermaProceso item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProcesoId,
            item.ProcesoProductivoId,
            item.ProcesoCodigo,
            item.ProcesoNombre,
            item.CantidadPerdida,
            item.Motivo,
            item.Observacion,
            item.RegistradoEn,
            item.RegistradoPorUsuarioId,
            item.RegistradoPorNombre);

    private static ControlCalidadDto MapQuality(ControlCalidad item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.ProductoTerminadoId,
            item.CalidadProductoId,
            item.CalidadCodigo,
            item.CalidadNombre,
            item.CantidadLadosA,
            item.CantidadLadosB,
            item.CantidadLadosC,
            item.CantidadLadosMerma,
            item.Resultado,
            item.Observacion,
            item.EvaluadoEn,
            item.EvaluadoPorUsuarioId,
            item.EvaluadoPorNombre);

    private static ProductoTerminadoListItemDto MapProductList(ProductoTerminado item) =>
        new(
            item.Id,
            item.Codigo,
            item.OrdenProduccionId,
            item.OrdenCodigo,
            item.CalidadProductoId,
            item.CalidadCodigo,
            item.CalidadNombre,
            item.FechaIngreso,
            item.CantidadPielesBuenas,
            item.CantidadLadosCalculada,
            item.CantidadLadosA,
            item.CantidadLadosB,
            item.CantidadLadosC,
            item.CantidadLadosMerma,
            item.Estado,
            item.Observacion,
            item.OrdenProductoId,
            item.ProductoNombre,
            item.ProductoColor,
            item.EsProductoIndividual);

    private static ProductoTerminadoDetailDto MapProduct(ProductoTerminado item) =>
        new(
            item.Id,
            item.Codigo,
            item.OrdenProduccionId,
            item.OrdenCodigo,
            item.CalidadProductoId,
            item.CalidadCodigo,
            item.CalidadNombre,
            item.FechaIngreso,
            item.CantidadPielesBuenas,
            item.CantidadLadosCalculada,
            item.CantidadLadosA,
            item.CantidadLadosB,
            item.CantidadLadosC,
            item.CantidadLadosMerma,
            item.Estado,
            item.Observacion,
            item.OrdenProductoId,
            item.ProductoNombre,
            item.ProductoColor,
            item.EsProductoIndividual);
}
