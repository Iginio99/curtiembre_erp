using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Ordenes;

public sealed class OrdenProduccionService(
    IOrdenProduccionRepository ordenProduccionRepository,
    ILoteRepository loteRepository,
    IClienteRepository clienteRepository,
    IProcesoProductivoLookupRepository procesoProductivoLookupRepository,
    IUsuarioLookupRepository usuarioLookupRepository,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<OrdenProduccionDetailDto>> UpdateResponsibleAsync(
        long orderId, UpdateResponsableRequestDto request, CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(orderId, cancellationToken);
        if (order is null)
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la orden.");
        if (order.Estado == "ANULADA" || order.Estado == "FINALIZADA")
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.Conflict, "No se puede editar una orden cerrada.");
        if (await usuarioLookupRepository.FindActiveByIdAsync(request.ResponsableUsuarioId, cancellationToken) is null)
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.Validation, "El responsable no esta activo.");
        await ordenProduccionRepository.UpdateOrderResponsibleAsync(orderId, request.ResponsableUsuarioId, cancellationToken);
        var updated = await ordenProduccionRepository.FindByIdAsync(orderId, cancellationToken);
        return UseCaseResult<OrdenProduccionDetailDto>.Ok(MapDetail(updated!), "Responsable actualizado.");
    }
    private static readonly string[] ExpectedSequenceCodes =
    [
        "REMOJO",
        "PELAMBRE",
        "CURTIDO",
        "RECURTIDO",
        "ACABADO"
    ];

    public async Task<IReadOnlyCollection<OrdenProduccionListItemDto>> ListAsync(
        OrdenProduccionFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await ordenProduccionRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<OrdenProduccionDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(id, cancellationToken);
        return order is null
            ? UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la orden de produccion.")
            : UseCaseResult<OrdenProduccionDetailDto>.Ok(MapDetail(order));
    }

    public async Task<UseCaseResult<OrdenProduccionDetailDto>> CreateAsync(
        CreateOrdenProduccionRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        var lote = await loteRepository.FindByIdAsync(request.LoteId, cancellationToken);
        if (lote is null)
        {
            errors.Add("No se encontro el lote seleccionado.");
        }
        else
        {
            if (lote.Estado == "ANULADO")
            {
                errors.Add("No se puede crear una orden con un lote anulado.");
            }

            if (lote.ClienteId != request.ClienteId)
            {
                errors.Add("El cliente seleccionado no coincide con el cliente del lote.");
            }

            if (request.CantidadPieles > lote.CantidadPielesDisponible)
            {
                errors.Add("La cantidad solicitada supera la disponibilidad actual del lote.");
            }
        }

        var cliente = await clienteRepository.FindByIdAsync(request.ClienteId, cancellationToken);
        if (cliente is null)
        {
            errors.Add("No se encontro el cliente seleccionado.");
        }
        else if (!cliente.Activo)
        {
            errors.Add("El cliente seleccionado esta inactivo.");
        }

        if (request.FechaFinEstimada == default)
        {
            errors.Add("La fecha fin estimada es obligatoria.");
        }

        if (request.FechaInicioPlanificada.HasValue &&
            request.FechaFinEstimada.Date < request.FechaInicioPlanificada.Value.Date)
        {
            errors.Add("La fecha fin estimada no puede ser menor que la fecha inicio planificada.");
        }

        UsuarioLookup? responsable = null;
        if (request.ResponsableUsuarioId.HasValue)
        {
            responsable = await usuarioLookupRepository.FindActiveByIdAsync(
                request.ResponsableUsuarioId.Value,
                cancellationToken);

            if (responsable is null)
            {
                errors.Add("No se encontro el responsable seleccionado o se encuentra inactivo.");
            }
        }

        var procesos = await procesoProductivoLookupRepository.ListBaseSequenceAsync(cancellationToken);
        if (procesos.Count != ExpectedSequenceCodes.Length ||
            procesos.Select(x => x.Codigo.ToUpperInvariant()).SequenceEqual(ExpectedSequenceCodes) is false)
        {
            errors.Add("La secuencia fija MVP de procesos no esta configurada correctamente. Se requiere: Remojo, Pelambre, Curtido, Recurtido y Acabado.");
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.Validation, string.Join(" ", errors));
        }

        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync("OP", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.Conflict, exception.Message);
        }

        var id = await ordenProduccionRepository.CreateAsync(
            new OrdenProduccion
            {
                Codigo = codigo,
                LoteId = request.LoteId,
                ClienteId = request.ClienteId,
                CantidadPieles = decimal.Round(request.CantidadPieles, 4),
                FechaInicioPlanificada = request.FechaInicioPlanificada?.Date,
                FechaFinEstimada = request.FechaFinEstimada.Date,
                ResponsableUsuarioId = responsable?.Id,
                Estado = "PROGRAMADA",
                Observacion = NormalizeNullable(request.Observacion),
                CreadoPorUsuarioId = actorId
            },
            procesos,
            cancellationToken);

        var created = await ordenProduccionRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se pudo recuperar la orden creada.")
            : UseCaseResult<OrdenProduccionDetailDto>.Ok(MapDetail(created), "Orden de produccion creada correctamente.");
    }

    public async Task<UseCaseResult<OrdenProduccionDetailDto>> StartAsync(
        long id,
        StartOrdenProduccionRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(id, cancellationToken);
        if (order is null)
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la orden de produccion.");
        }

        if (order.Estado != "PROGRAMADA")
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se pueden preparar ordenes en estado PROGRAMADA.");
        }

        if (request.ResponsableUsuarioId.HasValue &&
            await usuarioLookupRepository.FindActiveByIdAsync(request.ResponsableUsuarioId.Value, cancellationToken) is null)
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(
                ProduccionErrorCodes.Validation,
                "No se encontro el responsable seleccionado o se encuentra inactivo.");
        }

        if (request.PesoBaseKg <= 0)
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(
                ProduccionErrorCodes.Validation,
                "El peso base de Remojo debe ser mayor que 0 kg.");
        }

        if (request.FechaFinEstimada == default || request.FechaFinEstimada.Date < dateTimeProvider.Now.Date)
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(
                ProduccionErrorCodes.Validation,
                "La fecha estimada de termino de Remojo debe ser hoy o posterior.");
        }

        await ordenProduccionRepository.StartOrderAsync(
            id,
            request.ResponsableUsuarioId,
            decimal.Round(request.PesoBaseKg, 2),
            request.FechaFinEstimada.Date,
            NormalizeNullable(request.Observacion),
            dateTimeProvider.Now,
            cancellationToken);

        var started = await ordenProduccionRepository.FindByIdAsync(id, cancellationToken);
        return started is null
            ? UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la orden iniciada.")
            : UseCaseResult<OrdenProduccionDetailDto>.Ok(MapDetail(started), "Orden de produccion iniciada correctamente.");
    }

    public async Task<UseCaseResult<OrdenProduccionDetailDto>> CancelAsync(
        long id,
        CancelOrdenProduccionRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var order = await ordenProduccionRepository.FindByIdAsync(id, cancellationToken);
        if (order is null)
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la orden de produccion.");
        }

        if (order.Estado == "FINALIZADA")
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "No se puede anular una orden finalizada.");
        }

        if (order.Estado == "CANCELADA")
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "La orden ya se encuentra cancelada.");
        }

        if (order.Estado is not ("PROGRAMADA" or "LISTA_PARA_INICIAR"))
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se pueden cancelar ordenes en estado PROGRAMADA o LISTA_PARA_INICIAR.");
        }

        if (string.IsNullOrWhiteSpace(request.Motivo))
        {
            return UseCaseResult<OrdenProduccionDetailDto>.Fail(
                ProduccionErrorCodes.Validation,
                "El motivo de anulacion es obligatorio.");
        }

        await ordenProduccionRepository.CancelOrderAsync(
            id,
            request.Motivo.Trim(),
            actorId,
            dateTimeProvider.Now,
            cancellationToken);

        var cancelled = await ordenProduccionRepository.FindByIdAsync(id, cancellationToken);
        return cancelled is null
            ? UseCaseResult<OrdenProduccionDetailDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro la orden anulada.")
            : UseCaseResult<OrdenProduccionDetailDto>.Ok(MapDetail(cancelled), "Orden de produccion cancelada correctamente.");
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static OrdenProduccionListItemDto MapList(OrdenProduccion order) =>
        new(
            order.Id,
            order.Codigo,
            order.LoteId,
            order.LoteCodigo,
            order.ClienteId,
            order.ClienteRazonSocial,
            order.CantidadPieles,
            order.FechaInicioPlanificada,
            order.FechaInicioReal,
            order.FechaFinEstimada,
            order.FechaFinReal,
            order.ResponsableUsuarioId,
            order.ResponsableNombre,
            order.Estado,
            order.Observacion,
            order.ProcesosTotales,
            order.ProcesosFinalizados,
            order.CreadoEn);

    private static OrdenProduccionDetailDto MapDetail(OrdenProduccion order) =>
        new(
            order.Id,
            order.Codigo,
            order.LoteId,
            order.LoteCodigo,
            order.ClienteId,
            order.ClienteRazonSocial,
            order.CantidadPieles,
            order.FechaInicioPlanificada,
            order.FechaInicioReal,
            order.FechaFinEstimada,
            order.FechaFinReal,
            order.ResponsableUsuarioId,
            order.ResponsableNombre,
            order.Estado,
            order.MotivoAnulacion,
            order.Observacion,
            order.ProcesosTotales,
            order.ProcesosFinalizados,
            order.CreadoEn,
            order.CreadoPorUsuarioId,
            order.ActualizadoEn,
            order.ActualizadoPorUsuarioId);
}
