using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Application.Support;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Procesos;

public sealed class OrdenProcesoService(
    IOrdenProduccionRepository ordenProduccionRepository,
    IUsuarioLookupRepository usuarioLookupRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<OrdenProcesoListItemDto>> ListByOrderAsync(
        long ordenId,
        CancellationToken cancellationToken)
    {
        var items = await ordenProduccionRepository.ListProcessesAsync(ordenId, cancellationToken);
        return items.Select(MapProcess).ToArray();
    }

    public async Task<UseCaseResult<OrdenProcesoListItemDto>> StartAsync(
        long processId,
        StartOrdenProcesoRequestDto request,
        CancellationToken cancellationToken)
    {
        var process = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        if (process is null)
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso de la orden.");
        }

        if (process.Estado == "LISTA_PARA_INICIAR")
        {
            return await ExecuteAsync(processId, cancellationToken);
        }

        if (process.OrdenEstado is not ("EN_PROCESO" or "LISTA_PARA_INICIAR"))
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se pueden preparar procesos de ordenes activas.");
        }

        if (process.Estado != "PENDIENTE")
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se pueden iniciar procesos en estado PENDIENTE.");
        }

        var allProcesses = await ordenProduccionRepository.ListProcessesAsync(process.OrdenProduccionId, cancellationToken);
        if (allProcesses.Any(x => x.Secuencia < process.Secuencia && x.Estado != "FINALIZADO"))
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "No se puede iniciar el proceso mientras existan procesos previos sin finalizar.");
        }

        if (request.ResponsableUsuarioId.HasValue &&
            await usuarioLookupRepository.FindActiveByIdAsync(request.ResponsableUsuarioId.Value, cancellationToken) is null)
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Validation,
                "No se encontro el responsable seleccionado o se encuentra inactivo.");
        }

        if (request.PesoBaseKg <= 0)
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Validation,
                "El peso base del proceso debe ser mayor que 0 kg.");
        }

        if (request.FechaFinEstimada == default || request.FechaFinEstimada.Date < dateTimeProvider.Now.Date)
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Validation,
                "La fecha estimada de termino debe ser hoy o posterior.");
        }

        await ordenProduccionRepository.StartProcessAsync(
            processId,
            request.ResponsableUsuarioId,
            decimal.Round(request.PesoBaseKg, 2),
            request.FechaFinEstimada.Date,
            NormalizeNullable(request.Observacion),
            dateTimeProvider.Now,
            cancellationToken);

        var started = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        return started is null
            ? UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso iniciado.")
            : UseCaseResult<OrdenProcesoListItemDto>.Ok(MapProcess(started), "Proceso preparado y esperando materiales.");
    }

    public async Task<UseCaseResult<OrdenProcesoListItemDto>> ExecuteAsync(long processId, CancellationToken cancellationToken)
    {
        var process = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        if (process is null)
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso de la orden.");
        if (process.OrdenEstado != "LISTA_PARA_INICIAR" || process.Estado != "LISTA_PARA_INICIAR")
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.Conflict, "La etapa requiere la entrega completa de sus insumos antes de iniciar.");

        await ordenProduccionRepository.ExecuteProcessAsync(processId, dateTimeProvider.Now, cancellationToken);
        var executed = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        return executed is null
            ? UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso iniciado.")
            : UseCaseResult<OrdenProcesoListItemDto>.Ok(MapProcess(executed), "Proceso iniciado correctamente.");
    }

    public async Task<UseCaseResult<OrdenProcesoListItemDto>> FinishAsync(
        long processId,
        FinishOrdenProcesoRequestDto request,
        CancellationToken cancellationToken)
    {
        var process = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        if (process is null)
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso de la orden.");
        }

        if (process.OrdenEstado != "EN_PROCESO")
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se pueden finalizar procesos de ordenes en estado EN_PROCESO.");
        }

        if (process.Estado != "EN_PROCESO")
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "Solo se pueden finalizar procesos en estado EN_PROCESO.");
        }

        await ordenProduccionRepository.FinishProcessAsync(
            processId,
            NormalizeNullable(request.Observacion),
            dateTimeProvider.Now,
            cancellationToken);

        var finished = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        return finished is null
            ? UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso finalizado.")
            : UseCaseResult<OrdenProcesoListItemDto>.Ok(MapProcess(finished), "Proceso finalizado correctamente.");
    }

    public async Task<UseCaseResult<OrdenProcesoListItemDto>> UpdateObservationAsync(
        long processId,
        UpdateOrdenProcesoObservacionRequestDto request,
        CancellationToken cancellationToken)
    {
        var process = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        if (process is null)
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso de la orden.");
        }

        if (process.OrdenEstado == "ANULADA")
        {
            return UseCaseResult<OrdenProcesoListItemDto>.Fail(
                ProduccionErrorCodes.Conflict,
                "No se puede actualizar la observacion de un proceso cuya orden esta anulada.");
        }

        await ordenProduccionRepository.UpdateProcessObservationAsync(
            processId,
            NormalizeNullable(request.Observacion),
            cancellationToken);

        var updated = await ordenProduccionRepository.FindProcessByIdAsync(processId, cancellationToken);
        return updated is null
            ? UseCaseResult<OrdenProcesoListItemDto>.Fail(ProduccionErrorCodes.NotFound, "No se encontro el proceso actualizado.")
            : UseCaseResult<OrdenProcesoListItemDto>.Ok(MapProcess(updated), "Observacion del proceso actualizada correctamente.");
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static OrdenProcesoListItemDto MapProcess(OrdenProduccionProceso process) =>
        new(
            process.Id,
            process.OrdenProduccionId,
            process.ProcesoProductivoId,
            process.ProcesoCodigo,
            process.ProcesoNombre,
            process.Secuencia,
            process.ResponsableUsuarioId,
            process.ResponsableNombre,
            process.PesoBaseKg,
            process.FechaFinEstimada,
            process.FechaInicio,
            process.FechaFin,
            process.DiasReales,
            process.Estado,
            process.Observacion);
}
