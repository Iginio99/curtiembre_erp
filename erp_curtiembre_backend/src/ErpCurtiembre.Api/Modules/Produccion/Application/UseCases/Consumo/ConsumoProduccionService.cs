using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Consumo;

public sealed class ConsumoProduccionService(
    IOrdenProduccionRepository ordenProduccionRepository,
    IConsumoProduccionRepository consumoProduccionRepository,
    IProduccionInventarioGateway produccionInventarioGateway)
{
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
        foreach (var detail in gatewayResult.Details)
        {
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
                EsExtra = false
            });
        }

        await consumoProduccionRepository.RegisterRealConsumptionAsync(realItems, [], cancellationToken);
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
