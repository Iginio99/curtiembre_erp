using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Consumo;

public sealed class ConsumoProduccionService(
    IOrdenProduccionRepository ordenProduccionRepository,
    IConsumoProduccionRepository consumoProduccionRepository,
    IFormulaConsumptionLookupRepository formulaConsumptionLookupRepository,
    IProduccionInventarioGateway produccionInventarioGateway)
{
    public async Task<UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>> GeneratePlannedAsync(
        long ordenId,
        CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(ordenId, cancellationToken);
        if (order is null)
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Fail(
                ProduccionErrorCodes.NotFound,
                "No se encontro la orden de produccion.");
        }

        var processes = await ordenProduccionRepository.ListProcessesAsync(ordenId, cancellationToken);
        if (processes.Count == 0)
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Fail(
                ProduccionErrorCodes.Conflict,
                "La orden no tiene procesos configurados.");
        }

        var processesWithWeight = processes
            .Where(x => x.PesoBaseKg is > 0)
            .ToArray();

        if (processesWithWeight.Length == 0)
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Fail(
                ProduccionErrorCodes.Validation,
                "Inicie una etapa e ingrese su peso base en kg antes de calcular insumos.");
        }

        var existingItems = await consumoProduccionRepository.ListPlannedAsync(ordenId, cancellationToken);
        var processIdsWithPlan = existingItems
            .Select(x => x.OrdenProcesoId)
            .ToHashSet();

        var pendingProcesses = processesWithWeight
            .Where(x => !processIdsWithPlan.Contains(x.Id))
            .ToArray();

        if (pendingProcesses.Length == 0)
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Ok(
                existingItems.Select(MapPlanned).ToArray(),
                "El consumo planificado ya esta generado para las etapas iniciadas.");
        }

        var formulaDetails = await formulaConsumptionLookupRepository.ListCurrentDetailsByProcessIdsAsync(
            pendingProcesses.Select(x => x.ProcesoProductivoId).Distinct().ToArray(),
            DateTime.Today,
            cancellationToken);

        var duplicatedProcesses = formulaDetails
            .GroupBy(x => new { x.ProcesoProductivoId, x.InsumoId })
            .Where(x => x.Count() > 1)
            .Select(x => x.Key.ProcesoProductivoId)
            .Distinct()
            .ToArray();

        if (duplicatedProcesses.Length > 0)
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Fail(
                ProduccionErrorCodes.Conflict,
                "Existe mas de una formula vigente para al menos un proceso de la orden.");
        }

        var items = new List<OrdenConsumoPlanificado>();
        foreach (var process in pendingProcesses)
        {
            var processFormulaDetails = formulaDetails
                .Where(x => x.ProcesoProductivoId == process.ProcesoProductivoId)
                .ToArray();

            if (processFormulaDetails.Length == 0)
            {
                return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Fail(
                    ProduccionErrorCodes.Conflict,
                    $"No existe una formula vigente para el proceso {process.ProcesoNombre}.");
            }

            foreach (var detail in processFormulaDetails)
            {
                var cantidadPlanificada = decimal.Round(
                    (detail.Porcentaje * process.PesoBaseKg!.Value) / 100m,
                    2);

                items.Add(new OrdenConsumoPlanificado
                {
                    OrdenProduccionId = order.Id,
                    OrdenProcesoId = process.Id,
                    ProcesoProductivoId = process.ProcesoProductivoId,
                    ProcesoCodigo = process.ProcesoCodigo,
                    ProcesoNombre = process.ProcesoNombre,
                    FormulaVersionId = detail.FormulaVersionId,
                    InsumoId = detail.InsumoId,
                    InsumoCodigo = detail.InsumoCodigo,
                    InsumoNombre = detail.InsumoNombre,
                    Porcentaje = detail.Porcentaje,
                    CantidadPlanificada = cantidadPlanificada
                });
            }
        }

        await consumoProduccionRepository.RegisterPlannedConsumptionAsync(items, cancellationToken);
        var created = await consumoProduccionRepository.ListPlannedAsync(ordenId, cancellationToken);
        return UseCaseResult<IReadOnlyCollection<ConsumoPlanificadoItemDto>>.Ok(
            created.Select(MapPlanned).ToArray(),
            "Consumo planificado generado correctamente.");
    }

    public async Task<IReadOnlyCollection<ConsumoPlanificadoItemDto>> ListPlannedAsync(
        long ordenId,
        CancellationToken cancellationToken)
    {
        var items = await consumoProduccionRepository.ListPlannedAsync(ordenId, cancellationToken);
        return items.Select(MapPlanned).ToArray();
    }

    public async Task<UseCaseResult<IReadOnlyCollection<ConsumoRealItemDto>>> RequestConsumptionAsync(
        long ordenId,
        SolicitarConsumoProduccionRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(ordenId, cancellationToken);
        if (order is null)
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoRealItemDto>>.Fail(
                ProduccionErrorCodes.NotFound,
                "No se encontro la orden de produccion.");
        }

        if (order.Estado != "EN_PROCESO" && order.Estado != "ESPERANDO_MATERIALES")
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoRealItemDto>>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se puede registrar entrega para ordenes en proceso o esperando materiales.");
        }

        var process = await ordenProduccionRepository.FindProcessByIdAsync(request.OrdenProcesoId, cancellationToken);
        if (process is null || process.OrdenProduccionId != ordenId)
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoRealItemDto>>.Fail(
                ProduccionErrorCodes.Validation,
                "El proceso indicado no pertenece a la orden seleccionada.");
        }

        if (process.Estado != "EN_PROCESO" && process.Estado != "ESPERANDO_MATERIALES")
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoRealItemDto>>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se puede registrar entrega para procesos en proceso o esperando materiales.");
        }

        var plannedItems = await consumoProduccionRepository.ListPlannedAsync(ordenId, cancellationToken);
        if (!plannedItems.Any(x => x.OrdenProcesoId == process.Id))
        {
            var generated = await GeneratePlannedAsync(ordenId, cancellationToken);
            if (!generated.Success)
            {
                return UseCaseResult<IReadOnlyCollection<ConsumoRealItemDto>>.Fail(
                    generated.ErrorCode ?? ProduccionErrorCodes.Conflict,
                generated.Message);
            }

            plannedItems = await consumoProduccionRepository.ListPlannedAsync(ordenId, cancellationToken);
        }

        var processPlanned = plannedItems.Where(x => x.OrdenProcesoId == process.Id).ToArray();
        var accumulatedReal = await consumoProduccionRepository.ListAccumulatedRealByProcessAsync(
            ordenId,
            process.Id,
            cancellationToken);

        var accumulatedByInsumo = accumulatedReal.ToDictionary(x => x.InsumoId, x => x.CantidadConsumida);
        var plannedByInsumo = processPlanned
            .GroupBy(x => x.InsumoId)
            .ToDictionary(
                x => x.Key,
                x => new
                {
                    Total = x.Sum(v => v.CantidadPlanificada),
                    FirstPlannedId = x.First().Id
                });

        var gatewayResult = await produccionInventarioGateway.RegisterProcessConsumptionAsync(
            ordenId,
            process.Id,
            string.IsNullOrWhiteSpace(request.Motivo) ? $"Consumo del proceso {process.ProcesoNombre}" : request.Motivo!.Trim(),
            NormalizeNullable(request.Observacion),
            request.Detalles.Select(x => new InventoryProcessConsumptionDetailRequest(
                x.InsumoId,
                decimal.Round(x.Cantidad, 4),
                NormalizeNullable(x.Observacion))).ToArray(),
            actorId,
            cancellationToken);

        if (!gatewayResult.Success)
        {
            return UseCaseResult<IReadOnlyCollection<ConsumoRealItemDto>>.Fail(
                gatewayResult.ErrorCode ?? ProduccionErrorCodes.Conflict,
                gatewayResult.Message);
        }

        var realItems = new List<OrdenConsumoReal>();
        var desviaciones = new List<DesviacionConsumo>();

        foreach (var detail in gatewayResult.Details)
        {
            plannedByInsumo.TryGetValue(detail.InsumoId, out var plannedInfo);
            accumulatedByInsumo.TryGetValue(detail.InsumoId, out var consumedBefore);

            var remainingPlanned = plannedInfo is null
                ? 0m
                : Math.Max(0m, decimal.Round(plannedInfo.Total - consumedBefore, 4));

            var isExtra = detail.Cantidad > remainingPlanned || plannedInfo is null;

            realItems.Add(new OrdenConsumoReal
            {
                OrdenProduccionId = ordenId,
                OrdenProcesoId = process.Id,
                ProcesoProductivoId = process.ProcesoProductivoId,
                ProcesoCodigo = process.ProcesoCodigo,
                ProcesoNombre = process.ProcesoNombre,
                SalidaInventarioDetalleId = detail.SalidaInventarioDetalleId,
                InsumoId = detail.InsumoId,
                CantidadConsumida = detail.Cantidad,
                CostoUnitario = detail.CostoUnitario,
                EsExtra = isExtra
            });

            if (isExtra)
            {
                desviaciones.Add(new DesviacionConsumo
                {
                    OrdenConsumoPlanificadoId = plannedInfo?.FirstPlannedId,
                    CantidadPlanificada = remainingPlanned,
                    CantidadReal = detail.Cantidad,
                    Motivo = plannedInfo is null
                        ? "Consumo de insumo no planificado."
                        : "Consumo extra sobre el planificado."
                });
            }
        }

        await consumoProduccionRepository.RegisterRealConsumptionAsync(realItems, desviaciones, cancellationToken);
        var real = await consumoProduccionRepository.ListRealAsync(ordenId, cancellationToken);
        return UseCaseResult<IReadOnlyCollection<ConsumoRealItemDto>>.Ok(
            real.Where(x => x.OrdenProcesoId == process.Id).Select(MapReal).ToArray(),
            "Consumo real registrado correctamente.");
    }

    public async Task<IReadOnlyCollection<ConsumoRealItemDto>> ListRealAsync(
        long ordenId,
        CancellationToken cancellationToken)
    {
        var items = await consumoProduccionRepository.ListRealAsync(ordenId, cancellationToken);
        return items.Select(MapReal).ToArray();
    }

    public async Task<IReadOnlyCollection<DesviacionConsumoItemDto>> ListDeviationsAsync(
        long ordenId,
        CancellationToken cancellationToken)
    {
        var items = await consumoProduccionRepository.ListDeviationsAsync(ordenId, cancellationToken);
        return items.Select(MapDeviation).ToArray();
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static ConsumoPlanificadoItemDto MapPlanned(OrdenConsumoPlanificado item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProcesoId,
            item.ProcesoProductivoId,
            item.ProcesoCodigo,
            item.ProcesoNombre,
            item.FormulaVersionId,
            item.InsumoId,
            item.InsumoCodigo,
            item.InsumoNombre,
            item.Porcentaje,
            item.CantidadPlanificada,
            item.CreadoEn);

    private static ConsumoRealItemDto MapReal(OrdenConsumoReal item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProcesoId,
            item.ProcesoProductivoId,
            item.ProcesoCodigo,
            item.ProcesoNombre,
            item.SalidaInventarioDetalleId,
            item.InsumoId,
            item.InsumoCodigo,
            item.InsumoNombre,
            item.CantidadConsumida,
            item.CostoUnitario,
            item.CostoTotal,
            item.EsExtra,
            item.CreadoEn);

    private static DesviacionConsumoItemDto MapDeviation(DesviacionConsumo item) =>
        new(
            item.Id,
            item.OrdenConsumoPlanificadoId,
            item.OrdenConsumoRealId,
            item.OrdenProduccionId,
            item.OrdenProcesoId,
            item.ProcesoProductivoId,
            item.ProcesoCodigo,
            item.ProcesoNombre,
            item.InsumoId,
            item.InsumoCodigo,
            item.InsumoNombre,
            item.CantidadPlanificada,
            item.CantidadReal,
            item.CantidadDesviacion,
            item.Motivo,
            item.RegistradoEn);
}
