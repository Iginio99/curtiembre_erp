using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Costos;

public sealed class CostoProcesoService(
    ICostoProcesoRepository costoProcesoRepository,
    IProduccionFinanceLookupRepository produccionFinanceLookupRepository,
    IManoObraDirectaRepository manoObraDirectaRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<CostoProcesoListItemDto>> ListAsync(
        CostoProcesoFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await costoProcesoRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<CostoProcesoDetailDto>> GetByOrderProcessIdAsync(long ordenProcesoId, CancellationToken cancellationToken)
    {
        var item = await costoProcesoRepository.FindByOrderProcessIdAsync(ordenProcesoId, cancellationToken);
        return item is null
            ? UseCaseResult<CostoProcesoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el costo del proceso.")
            : UseCaseResult<CostoProcesoDetailDto>.Ok(MapDetail(item));
    }

    public async Task<UseCaseResult<CostoProcesoDetailDto>> CalculateAsync(
        CalculoCostoProcesoRequestDto request,
        CancellationToken cancellationToken)
    {
        var proceso = await produccionFinanceLookupRepository.FindProcessAsync(request.OrdenProcesoId, cancellationToken);
        if (proceso is null)
        {
            return UseCaseResult<CostoProcesoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el proceso productivo.");
        }

        if (proceso.OrdenProduccionId != request.OrdenProduccionId)
        {
            return UseCaseResult<CostoProcesoDetailDto>.Fail(
                FinanzasErrorCodes.Validation,
                "El proceso indicado no pertenece a la orden de produccion enviada.");
        }

        var consumos = await produccionFinanceLookupRepository.ListConsumedCostByProcessAsync(
            request.OrdenProduccionId,
            cancellationToken);
        var consumoProceso = consumos.SingleOrDefault(x => x.OrdenProcesoId == request.OrdenProcesoId);

        var manoObra = await manoObraDirectaRepository.ListAsync(
            new ManoObraDirectaFiltersDto(request.OrdenProduccionId, request.OrdenProcesoId),
            cancellationToken);

        var entity = new CostoProceso
        {
            OrdenProduccionId = proceso.OrdenProduccionId,
            OrdenProduccionCodigo = proceso.OrdenProduccionCodigo,
            OrdenProcesoId = proceso.OrdenProcesoId,
            ProcesoCodigo = proceso.ProcesoCodigo,
            ProcesoNombre = proceso.ProcesoNombre,
            CostoInsumos = decimal.Round(consumoProceso?.CostoInsumos ?? 0, 2),
            CostoManoObra = decimal.Round(manoObra.Sum(x => x.Monto), 2),
            CalculadoEn = dateTimeProvider.Now
        };

        await costoProcesoRepository.UpsertAsync(entity, cancellationToken);
        var stored = await costoProcesoRepository.FindByOrderProcessIdAsync(request.OrdenProcesoId, cancellationToken);

        return stored is null
            ? UseCaseResult<CostoProcesoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el costo calculado.")
            : UseCaseResult<CostoProcesoDetailDto>.Ok(MapDetail(stored), "Costo del proceso calculado correctamente.");
    }

    private static CostoProcesoListItemDto MapList(CostoProceso item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProduccionCodigo,
            item.OrdenProcesoId,
            item.ProcesoCodigo,
            item.ProcesoNombre,
            item.CostoInsumos,
            item.CostoManoObra,
            item.CostoTotal,
            item.CalculadoEn);

    private static CostoProcesoDetailDto MapDetail(CostoProceso item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProduccionCodigo,
            item.OrdenProcesoId,
            item.ProcesoCodigo,
            item.ProcesoNombre,
            item.CostoInsumos,
            item.CostoManoObra,
            item.CostoTotal,
            item.CalculadoEn);
}
