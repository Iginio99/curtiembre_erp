using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Costos;

public sealed class CostoOrdenService(
    ICostoOrdenRepository costoOrdenRepository,
    IPeriodoCostoRepository periodoCostoRepository,
    IProduccionFinanceLookupRepository produccionFinanceLookupRepository,
    IManoObraDirectaRepository manoObraDirectaRepository,
    ICostoIndirectoRepository costoIndirectoRepository,
    IDepreciacionPeriodoRepository depreciacionPeriodoRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<CostoOrdenListItemDto>> ListAsync(
        CostoOrdenFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await costoOrdenRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<CostoOrdenDetailDto>> GetByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken)
    {
        var item = await costoOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        return item is null
            ? UseCaseResult<CostoOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el costo de la orden.")
            : UseCaseResult<CostoOrdenDetailDto>.Ok(MapDetail(item));
    }

    public async Task<UseCaseResult<CostoOrdenDetailDto>> CalculateEstimatedAsync(
        long ordenProduccionId,
        long actorId,
        CancellationToken cancellationToken)
    {
        var snapshot = await produccionFinanceLookupRepository.FindOrderSnapshotAsync(ordenProduccionId, cancellationToken);
        if (snapshot is null)
        {
            return UseCaseResult<CostoOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro la orden de produccion.");
        }

        var planned = await produccionFinanceLookupRepository.GetPlannedCostByOrderAsync(ordenProduccionId, cancellationToken);
        var manoObra = await manoObraDirectaRepository.ListAsync(
            new ManoObraDirectaFiltersDto(ordenProduccionId, null),
            cancellationToken);

        var costoPieles = snapshot.ClienteTraeLote ? 0 : decimal.Round(snapshot.CostoPielesTotal, 2);
        var costoInsumos = decimal.Round(planned?.CostoInsumos ?? 0, 2);
        var costoManoObra = decimal.Round(manoObra.Sum(x => x.Monto), 2);

        var entity = new CostoOrden
        {
            OrdenProduccionId = snapshot.OrdenProduccionId,
            OrdenProduccionCodigo = snapshot.OrdenProduccionCodigo,
            CostoPieles = costoPieles,
            CostoInsumos = costoInsumos,
            CostoManoObra = costoManoObra,
            CostoIndirectoAsignado = 0,
            CostoDepreciacionAsignado = 0,
            PielesBuenasFinales = snapshot.PielesBuenasFinales,
            CostoPorPiel = CalculateCostoPorPiel(
                costoPieles + costoInsumos + costoManoObra,
                snapshot.PielesBuenasFinales),
            CostoEstimado = decimal.Round(costoPieles + costoInsumos + costoManoObra, 2),
            CostoReal = null,
            Estado = "ESTIMADO",
            CalculadoEn = dateTimeProvider.Now,
            CalculadoPorUsuarioId = actorId
        };

        await costoOrdenRepository.UpsertAsync(entity, cancellationToken);
        var stored = await costoOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        return stored is null
            ? UseCaseResult<CostoOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el costo estimado.")
            : UseCaseResult<CostoOrdenDetailDto>.Ok(MapDetail(stored), "Costo estimado de la orden calculado correctamente.");
    }

    public async Task<UseCaseResult<CostoOrdenDetailDto>> CalculateRealAsync(
        long ordenProduccionId,
        long actorId,
        CancellationToken cancellationToken)
    {
        var snapshot = await produccionFinanceLookupRepository.FindOrderSnapshotAsync(ordenProduccionId, cancellationToken);
        if (snapshot is null)
        {
            return UseCaseResult<CostoOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro la orden de produccion.");
        }

        if (snapshot.FechaFinReal is null)
        {
            return UseCaseResult<CostoOrdenDetailDto>.Fail(
                FinanzasErrorCodes.Conflict,
                "La orden debe estar finalizada para calcular el costo real.");
        }

        var periodo = await ResolvePeriodoAsync(snapshot.FechaFinReal.Value, cancellationToken);
        if (periodo is null)
        {
            return UseCaseResult<CostoOrdenDetailDto>.Fail(
                FinanzasErrorCodes.Conflict,
                "No existe un periodo de costo para la fecha de cierre de la orden.");
        }

        var consumed = await produccionFinanceLookupRepository.GetConsumedCostByOrderAsync(ordenProduccionId, cancellationToken);
        var manoObra = await manoObraDirectaRepository.ListAsync(
            new ManoObraDirectaFiltersDto(ordenProduccionId, null),
            cancellationToken);
        var indirectos = await costoIndirectoRepository.ListAsync(
            new CostoIndirectoFiltersDto(periodo.Id, null, null),
            cancellationToken);
        var depreciaciones = await depreciacionPeriodoRepository.ListAsync(
            new DepreciacionPeriodoFiltersDto(periodo.Id, null),
            cancellationToken);

        var costoPieles = snapshot.ClienteTraeLote ? 0 : decimal.Round(snapshot.CostoPielesTotal, 2);
        var costoInsumos = decimal.Round(consumed?.CostoInsumos ?? 0, 2);
        var costoManoObra = decimal.Round(manoObra.Sum(x => x.Monto), 2);
        var costoIndirecto = await CalculateIndirectoAsignadoAsync(
            periodo,
            indirectos.Sum(x => x.Monto),
            snapshot.CantidadPieles,
            cancellationToken);
        var costoDepreciacion = await CalculateDepreciacionAsignadaAsync(
            periodo,
            depreciaciones.Sum(x => x.MontoDepreciacion),
            snapshot.CantidadPieles,
            cancellationToken);
        var costoTotal = decimal.Round(costoPieles + costoInsumos + costoManoObra + costoIndirecto + costoDepreciacion, 2);

        var entity = new CostoOrden
        {
            OrdenProduccionId = snapshot.OrdenProduccionId,
            OrdenProduccionCodigo = snapshot.OrdenProduccionCodigo,
            PeriodoCostoId = periodo.Id,
            PeriodoAnio = periodo.Anio,
            PeriodoMes = periodo.Mes,
            CostoPieles = costoPieles,
            CostoInsumos = costoInsumos,
            CostoManoObra = costoManoObra,
            CostoIndirectoAsignado = costoIndirecto,
            CostoDepreciacionAsignado = costoDepreciacion,
            PielesBuenasFinales = snapshot.PielesBuenasFinales,
            CostoPorPiel = CalculateCostoPorPiel(costoTotal, snapshot.PielesBuenasFinales),
            CostoEstimado = null,
            CostoReal = costoTotal,
            Estado = "REAL",
            CalculadoEn = dateTimeProvider.Now,
            CalculadoPorUsuarioId = actorId
        };

        await costoOrdenRepository.UpsertAsync(entity, cancellationToken);
        var stored = await costoOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        return stored is null
            ? UseCaseResult<CostoOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el costo real.")
            : UseCaseResult<CostoOrdenDetailDto>.Ok(MapDetail(stored), "Costo real de la orden calculado correctamente.");
    }

    public async Task<UseCaseResult<CostoOrdenDetailDto>> CloseAsync(
        long ordenProduccionId,
        long actorId,
        CancellationToken cancellationToken)
    {
        var existing = await costoOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<CostoOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No existe costo de orden para cerrar.");
        }

        if (existing.Estado != "REAL")
        {
            return UseCaseResult<CostoOrdenDetailDto>.Fail(
                FinanzasErrorCodes.Conflict,
                "Solo se puede cerrar un costo de orden que este en estado REAL.");
        }

        var entity = new CostoOrden
        {
            Id = existing.Id,
            OrdenProduccionId = existing.OrdenProduccionId,
            OrdenProduccionCodigo = existing.OrdenProduccionCodigo,
            PeriodoCostoId = existing.PeriodoCostoId,
            PeriodoAnio = existing.PeriodoAnio,
            PeriodoMes = existing.PeriodoMes,
            CostoPieles = existing.CostoPieles,
            CostoInsumos = existing.CostoInsumos,
            CostoManoObra = existing.CostoManoObra,
            CostoIndirectoAsignado = existing.CostoIndirectoAsignado,
            CostoDepreciacionAsignado = existing.CostoDepreciacionAsignado,
            PielesBuenasFinales = existing.PielesBuenasFinales,
            CostoPorPiel = existing.CostoPorPiel,
            CostoEstimado = existing.CostoEstimado,
            CostoReal = existing.CostoReal,
            Estado = "CERRADO",
            CalculadoEn = dateTimeProvider.Now,
            CalculadoPorUsuarioId = actorId
        };

        await costoOrdenRepository.UpsertAsync(entity, cancellationToken);
        var stored = await costoOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        return stored is null
            ? UseCaseResult<CostoOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el costo cerrado.")
            : UseCaseResult<CostoOrdenDetailDto>.Ok(MapDetail(stored), "Costo de orden cerrado correctamente.");
    }

    private async Task<PeriodoCosto?> ResolvePeriodoAsync(DateTime fechaFinReal, CancellationToken cancellationToken)
    {
        var periodos = await periodoCostoRepository.ListAsync(
            new PeriodoCostoFiltersDto(fechaFinReal.Year, fechaFinReal.Month, null),
            cancellationToken);

        return periodos.SingleOrDefault();
    }

    private async Task<decimal> CalculateIndirectoAsignadoAsync(
        PeriodoCosto periodo,
        decimal totalIndirectosPeriodo,
        decimal cantidadPielesOrden,
        CancellationToken cancellationToken)
    {
        var totalPielesPeriodo = await produccionFinanceLookupRepository.GetTotalSkinsClosedInPeriodAsync(
            periodo.Anio,
            periodo.Mes,
            cancellationToken);

        if (totalIndirectosPeriodo <= 0 || totalPielesPeriodo <= 0 || cantidadPielesOrden <= 0)
        {
            return 0;
        }

        return decimal.Round(totalIndirectosPeriodo * (cantidadPielesOrden / totalPielesPeriodo), 2, MidpointRounding.AwayFromZero);
    }

    private async Task<decimal> CalculateDepreciacionAsignadaAsync(
        PeriodoCosto periodo,
        decimal totalDepreciacionPeriodo,
        decimal cantidadPielesOrden,
        CancellationToken cancellationToken)
    {
        var totalPielesPeriodo = await produccionFinanceLookupRepository.GetTotalSkinsClosedInPeriodAsync(
            periodo.Anio,
            periodo.Mes,
            cancellationToken);

        if (totalDepreciacionPeriodo <= 0 || totalPielesPeriodo <= 0 || cantidadPielesOrden <= 0)
        {
            return 0;
        }

        return decimal.Round(totalDepreciacionPeriodo * (cantidadPielesOrden / totalPielesPeriodo), 2, MidpointRounding.AwayFromZero);
    }

    private static decimal? CalculateCostoPorPiel(decimal costoTotal, decimal? pielesBuenasFinales)
    {
        if (pielesBuenasFinales is null || pielesBuenasFinales <= 0)
        {
            return null;
        }

        return decimal.Round(costoTotal / pielesBuenasFinales.Value, 4, MidpointRounding.AwayFromZero);
    }

    private static CostoOrdenListItemDto MapList(CostoOrden item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProduccionCodigo,
            item.PeriodoCostoId,
            item.PeriodoAnio,
            item.PeriodoMes,
            item.CostoPieles,
            item.CostoInsumos,
            item.CostoManoObra,
            item.CostoIndirectoAsignado,
            item.CostoDepreciacionAsignado,
            item.CostoTotal,
            item.PielesBuenasFinales,
            item.CostoPorPiel,
            item.CostoEstimado,
            item.CostoReal,
            item.Estado,
            item.CalculadoEn,
            item.CalculadoPorUsuarioId);

    private static CostoOrdenDetailDto MapDetail(CostoOrden item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProduccionCodigo,
            item.PeriodoCostoId,
            item.PeriodoAnio,
            item.PeriodoMes,
            item.CostoPieles,
            item.CostoInsumos,
            item.CostoManoObra,
            item.CostoIndirectoAsignado,
            item.CostoDepreciacionAsignado,
            item.CostoTotal,
            item.PielesBuenasFinales,
            item.CostoPorPiel,
            item.CostoEstimado,
            item.CostoReal,
            item.Estado,
            item.CalculadoEn,
            item.CalculadoPorUsuarioId);
}
