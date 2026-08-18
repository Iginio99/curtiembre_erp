using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Application.UseCases.Consumo;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Solicitudes;

public sealed class SolicitudInsumoService(
    IOrdenProduccionRepository ordenProduccionRepository,
    IConsumoProduccionRepository consumoProduccionRepository,
    ISolicitudInsumoRepository solicitudInsumoRepository,
    ISolicitudInsumoAlertService solicitudInsumoAlertService,
    ConsumoProduccionService consumoProduccionService,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<SolicitudInsumoListItemDto>> ListAsync(
        string? estado,
        CancellationToken cancellationToken)
    {
        var requests = await solicitudInsumoRepository.ListAsync(estado, cancellationToken);
        var items = new List<SolicitudInsumoListItemDto>();
        foreach (var request in requests)
        {
            var details = await solicitudInsumoRepository.ListDetailsAsync(request.Id, cancellationToken);
            items.Add(MapList(request, details));
        }

        return items;
    }

    public async Task<UseCaseResult<SolicitudInsumoDetailDto>> GetByIdAsync(
        long id,
        CancellationToken cancellationToken)
    {
        var request = await solicitudInsumoRepository.FindByIdAsync(id, cancellationToken);
        if (request is null)
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.NotFound,
                "No se encontro la solicitud de insumos.");
        }

        var details = await solicitudInsumoRepository.ListDetailsAsync(id, cancellationToken);
        return UseCaseResult<SolicitudInsumoDetailDto>.Ok(MapDetail(request, details));
    }

    public async Task<UseCaseResult<SolicitudInsumoDetailDto>> CreateAsync(
        long ordenId,
        long procesoId,
        CrearSolicitudInsumoRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(ordenId, cancellationToken);
        if (order is null)
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.NotFound,
                "No se encontro la orden de produccion.");
        }

        var process = await ordenProduccionRepository.FindProcessByIdAsync(procesoId, cancellationToken);
        if (process is null || process.OrdenProduccionId != ordenId)
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.Validation,
                "La etapa indicada no pertenece a la orden seleccionada.");
        }

        if (process.Estado != "ESPERANDO_MATERIALES")
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La solicitud se puede crear solo para una etapa esperando materiales.");
        }

        if (await solicitudInsumoRepository.HasOpenRequestForProcessAsync(procesoId, cancellationToken))
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La etapa ya tiene una solicitud de insumos pendiente de atencion.");
        }

        var plannedItems = await consumoProduccionRepository.ListPlannedAsync(ordenId, cancellationToken);
        if (!plannedItems.Any(x => x.OrdenProcesoId == procesoId))
        {
            var generated = await consumoProduccionService.GeneratePlannedAsync(ordenId, cancellationToken);
            if (!generated.Success)
            {
                return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                    generated.ErrorCode ?? ProduccionErrorCodes.Conflict,
                    generated.Message);
            }

            plannedItems = await consumoProduccionRepository.ListPlannedAsync(ordenId, cancellationToken);
        }

        var planByInsumo = plannedItems
            .Where(x => x.OrdenProcesoId == procesoId)
            .GroupBy(x => x.InsumoId)
            .ToDictionary(x => x.Key, x => decimal.Round(x.Sum(y => y.CantidadPlanificada), 2));
        var errors = new List<string>();
        var requestedInsumos = new HashSet<long>();
        var details = new List<SolicitudInsumoDetalle>();

        foreach (var detail in request.Detalles)
        {
            if (!requestedInsumos.Add(detail.InsumoId))
            {
                errors.Add($"El insumo {detail.InsumoId} no debe repetirse en la solicitud.");
                continue;
            }

            if (!planByInsumo.TryGetValue(detail.InsumoId, out var plannedQuantity))
            {
                errors.Add($"El insumo {detail.InsumoId} no forma parte de la formula de {process.ProcesoNombre}.");
                continue;
            }

            var quantity = decimal.Round(detail.Cantidad, 2);
            if (quantity <= 0 || quantity > plannedQuantity)
            {
                errors.Add($"La cantidad solicitada del insumo {detail.InsumoId} debe ser mayor que 0 y no superar {plannedQuantity:0.00}.");
                continue;
            }

            details.Add(new SolicitudInsumoDetalle
            {
                InsumoId = detail.InsumoId,
                CantidadSolicitada = quantity,
                Observacion = NormalizeNullable(detail.Observacion)
            });
        }

        if (details.Count == 0)
        {
            errors.Add("Debes solicitar al menos un insumo de la formula planificada.");
        }

        if (details.Count != planByInsumo.Count || details.Any(x => !planByInsumo.ContainsKey(x.InsumoId)))
        {
            errors.Add("La solicitud debe incluir todos los insumos planificados de la etapa; las entregas parciales no habilitan su inicio.");
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.Validation,
                string.Join(" ", errors));
        }

        string code;
        try
        {
            code = await documentSequenceService.GenerateNextAsync("SOL", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(ProduccionErrorCodes.Conflict, exception.Message);
        }

        var id = await solicitudInsumoRepository.CreateAsync(
            new SolicitudInsumo
            {
                Codigo = code,
                OrdenProduccionId = ordenId,
                OrdenProcesoId = procesoId,
                Estado = "SOLICITADA",
                Observacion = NormalizeNullable(request.Observacion),
                SolicitadoEn = dateTimeProvider.Now,
                SolicitadoPorUsuarioId = actorId
            },
            details,
            cancellationToken);
        await solicitudInsumoAlertService.CreatePendingAsync(id, code, cancellationToken);

        return await GetByIdAsync(id, cancellationToken);
    }

    public async Task<UseCaseResult<SolicitudInsumoDetailDto>> DeliverAsync(
        long id,
        EntregarSolicitudInsumoRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var solicitud = await solicitudInsumoRepository.FindByIdAsync(id, cancellationToken);
        if (solicitud is null)
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.NotFound,
                "No se encontro la solicitud de insumos.");
        }

        if (solicitud.Estado == "ENTREGADA")
        {
            return await GetByIdAsync(id, cancellationToken);
        }

        if (solicitud.Estado != "SOLICITADA")
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se pueden entregar solicitudes en estado SOLICITADA.");
        }

        var details = await solicitudInsumoRepository.ListDetailsAsync(id, cancellationToken);
        if (details.Count == 0)
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La solicitud no tiene insumos para entregar.");
        }

        if (!await solicitudInsumoRepository.TryStartDeliveryAsync(id, cancellationToken))
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La solicitud esta siendo atendida o ya fue entregada por otro usuario.");
        }

        var consumption = await consumoProduccionService.RequestConsumptionAsync(
            solicitud.OrdenProduccionId,
            new SolicitarConsumoProduccionRequestDto(
                solicitud.OrdenProcesoId,
                string.IsNullOrWhiteSpace(request.Motivo)
                    ? $"Entrega de solicitud {solicitud.Codigo}"
                    : request.Motivo.Trim(),
                NormalizeNullable(request.Observacion),
                details.Select(x => new SolicitarConsumoDetalleRequestDto(
                    x.InsumoId,
                    x.CantidadSolicitada,
                    x.Observacion)).ToArray()),
            actorId,
            cancellationToken);
        if (!consumption.Success)
        {
            await solicitudInsumoRepository.ReopenDeliveryAsync(id, cancellationToken);
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                consumption.ErrorCode ?? ProduccionErrorCodes.Conflict,
                consumption.Message);
        }

        if (!await solicitudInsumoRepository.CompleteDeliveryAsync(id, cancellationToken))
        {
            return UseCaseResult<SolicitudInsumoDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La solicitud ya fue atendida por otro usuario. El stock no se volvio a descontar.");
        }

        await ordenProduccionRepository.MarkProcessReadyToStartAsync(
            solicitud.OrdenProcesoId,
            cancellationToken);
        await solicitudInsumoAlertService.CloseAsync(id, actorId, cancellationToken);

        return await GetByIdAsync(id, cancellationToken);
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static SolicitudInsumoListItemDto MapList(
        SolicitudInsumo request,
        IReadOnlyCollection<SolicitudInsumoDetalle> details) =>
        new(
            request.Id, request.Codigo, request.OrdenProduccionId, request.OrdenCodigo,
            request.OrdenProcesoId, request.ProcesoCodigo, request.ProcesoNombre,
            request.Estado, request.Observacion, request.SolicitadoEn,
            request.SolicitadoPorUsuarioId, request.SolicitadoPorNombre,
            details.Count, details.Sum(x => x.CantidadSolicitada));

    private static SolicitudInsumoDetailDto MapDetail(
        SolicitudInsumo request,
        IReadOnlyCollection<SolicitudInsumoDetalle> details) =>
        new(
            request.Id, request.Codigo, request.OrdenProduccionId, request.OrdenCodigo,
            request.OrdenProcesoId, request.ProcesoCodigo, request.ProcesoNombre,
            request.Estado, request.Observacion, request.SolicitadoEn,
            request.SolicitadoPorUsuarioId, request.SolicitadoPorNombre,
            details.Select(x => new SolicitudInsumoDetalleDto(
                x.Id, x.InsumoId, x.InsumoCodigo, x.InsumoNombre,
                x.UnidadMedidaCodigo, x.UnidadMedidaNombre,
                x.CantidadSolicitada, x.Observacion)).ToArray());
}
