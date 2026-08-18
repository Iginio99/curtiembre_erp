using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Depreciaciones;

public sealed class DepreciacionPeriodoService(
    IDepreciacionPeriodoRepository depreciacionPeriodoRepository,
    IPeriodoCostoRepository periodoCostoRepository,
    IActivoDepreciableRepository activoDepreciableRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<DepreciacionPeriodoListItemDto>> ListAsync(
        DepreciacionPeriodoFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await depreciacionPeriodoRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<DepreciacionPeriodoDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var item = await depreciacionPeriodoRepository.FindByIdAsync(id, cancellationToken);
        return item is null
            ? UseCaseResult<DepreciacionPeriodoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro la depreciacion del periodo.")
            : UseCaseResult<DepreciacionPeriodoDetailDto>.Ok(MapDetail(item));
    }

    public async Task<UseCaseResult<CalculoDepreciacionResultDto>> CalculateForPeriodAsync(
        long periodoCostoId,
        CancellationToken cancellationToken)
    {
        var periodo = await periodoCostoRepository.FindByIdAsync(periodoCostoId, cancellationToken);
        if (periodo is null)
        {
            return UseCaseResult<CalculoDepreciacionResultDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el periodo de costo.");
        }

        if (periodo.Estado != "ABIERTO")
        {
            return UseCaseResult<CalculoDepreciacionResultDto>.Fail(
                FinanzasErrorCodes.Conflict,
                "Solo se puede calcular depreciacion en periodos abiertos.");
        }

        var activos = await activoDepreciableRepository.ListEligibleForPeriodAsync(periodo.FechaFin, cancellationToken);
        var registrados = await depreciacionPeriodoRepository.ListRegisteredAssetIdsByPeriodAsync(periodoCostoId, cancellationToken);
        var registradosSet = registrados.ToHashSet();
        var now = dateTimeProvider.Now;

        var nuevas = activos
            .Where(x => !registradosSet.Contains(x.Id))
            .Select(x => new DepreciacionPeriodo
            {
                PeriodoCostoId = periodo.Id,
                PeriodoAnio = periodo.Anio,
                PeriodoMes = periodo.Mes,
                ActivoDepreciableId = x.Id,
                ActivoCodigo = x.Codigo,
                ActivoNombre = x.Nombre,
                MontoDepreciacion = CalculateMonthlyDepreciation(x),
                CalculadoEn = now
            })
            .ToArray();

        await depreciacionPeriodoRepository.CreateManyAsync(nuevas, cancellationToken);

        var created = nuevas.Length == 0
            ? Array.Empty<DepreciacionPeriodoDetailDto>()
            : (await depreciacionPeriodoRepository.ListAsync(
                    new DepreciacionPeriodoFiltersDto(periodoCostoId, null),
                    cancellationToken))
                .Where(x => nuevas.Any(n => n.ActivoDepreciableId == x.ActivoDepreciableId))
                .Select(MapDetail)
                .ToArray();

        var result = new CalculoDepreciacionResultDto(
            periodo.Id,
            periodo.Anio,
            periodo.Mes,
            activos.Count,
            nuevas.Length,
            nuevas.Sum(x => x.MontoDepreciacion),
            created);

        return UseCaseResult<CalculoDepreciacionResultDto>.Ok(result, "Depreciacion del periodo calculada correctamente.");
    }

    private static decimal CalculateMonthlyDepreciation(ActivoDepreciable activo) =>
        activo.VidaUtilMeses <= 0
            ? 0
            : decimal.Round((activo.ValorCompra - activo.ValorResidual) / activo.VidaUtilMeses, 2, MidpointRounding.AwayFromZero);

    private static DepreciacionPeriodoListItemDto MapList(DepreciacionPeriodo item) =>
        new(
            item.Id,
            item.PeriodoCostoId,
            item.PeriodoAnio,
            item.PeriodoMes,
            item.ActivoDepreciableId,
            item.ActivoCodigo,
            item.ActivoNombre,
            item.MontoDepreciacion,
            item.CalculadoEn);

    private static DepreciacionPeriodoDetailDto MapDetail(DepreciacionPeriodo item) =>
        new(
            item.Id,
            item.PeriodoCostoId,
            item.PeriodoAnio,
            item.PeriodoMes,
            item.ActivoDepreciableId,
            item.ActivoCodigo,
            item.ActivoNombre,
            item.MontoDepreciacion,
            item.CalculadoEn);
}
