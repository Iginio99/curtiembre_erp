using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Periodos;

public sealed class PeriodoCostoService(
    IPeriodoCostoRepository periodoCostoRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<PeriodoCostoListItemDto>> ListAsync(
        PeriodoCostoFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await periodoCostoRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<PeriodoCostoDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var periodo = await periodoCostoRepository.FindByIdAsync(id, cancellationToken);
        return periodo is null
            ? UseCaseResult<PeriodoCostoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el periodo de costo.")
            : UseCaseResult<PeriodoCostoDetailDto>.Ok(MapDetail(periodo));
    }

    public async Task<UseCaseResult<PeriodoCostoDetailDto>> CreateAsync(
        CreatePeriodoCostoRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = await ValidateCreateAsync(request, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<PeriodoCostoDetailDto>.Fail(FinanzasErrorCodes.Validation, string.Join(" ", errors));
        }

        var fechaInicio = new DateTime(request.Anio, request.Mes, 1);
        var fechaFin = fechaInicio.AddMonths(1).AddDays(-1);

        var id = await periodoCostoRepository.CreateAsync(
            new PeriodoCosto
            {
                Anio = request.Anio,
                Mes = request.Mes,
                FechaInicio = fechaInicio,
                FechaFin = fechaFin,
                Estado = "ABIERTO",
                Observacion = NormalizeNullable(request.Observacion)
            },
            cancellationToken);

        var created = await periodoCostoRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<PeriodoCostoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el periodo creado.")
            : UseCaseResult<PeriodoCostoDetailDto>.Ok(MapDetail(created), "Periodo de costo creado correctamente.");
    }

    public async Task<UseCaseResult<PeriodoCostoDetailDto>> CloseAsync(
        long id,
        long actorId,
        ClosePeriodoCostoRequestDto request,
        CancellationToken cancellationToken)
    {
        var existing = await periodoCostoRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<PeriodoCostoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el periodo de costo.");
        }

        if (existing.Estado == "CERRADO")
        {
            return UseCaseResult<PeriodoCostoDetailDto>.Fail(FinanzasErrorCodes.Conflict, "El periodo ya esta cerrado.");
        }

        var observacion = NormalizeNullable(request.Observacion) ?? existing.Observacion;
        if (observacion is not null && observacion.Length > 500)
        {
            return UseCaseResult<PeriodoCostoDetailDto>.Fail(
                FinanzasErrorCodes.Validation,
                "La observacion no debe superar 500 caracteres.");
        }

        await periodoCostoRepository.CloseAsync(id, dateTimeProvider.Now, actorId, observacion, cancellationToken);

        var updated = await periodoCostoRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<PeriodoCostoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el periodo actualizado.")
            : UseCaseResult<PeriodoCostoDetailDto>.Ok(MapDetail(updated), "Periodo de costo cerrado correctamente.");
    }

    private async Task<IReadOnlyCollection<string>> ValidateCreateAsync(
        CreatePeriodoCostoRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        if (request.Anio < 2000 || request.Anio > 2100)
        {
            errors.Add("El anio debe estar entre 2000 y 2100.");
        }

        if (request.Mes is < 1 or > 12)
        {
            errors.Add("El mes debe estar entre 1 y 12.");
        }

        var observacion = NormalizeNullable(request.Observacion);
        if (observacion is not null && observacion.Length > 500)
        {
            errors.Add("La observacion no debe superar 500 caracteres.");
        }

        if (errors.Count == 0 &&
            await periodoCostoRepository.ExistsByYearMonthAsync(request.Anio, request.Mes, null, cancellationToken))
        {
            errors.Add("Ya existe un periodo de costo para el anio y mes indicados.");
        }

        return errors;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static PeriodoCostoListItemDto MapList(PeriodoCosto item) =>
        new(
            item.Id,
            item.Anio,
            item.Mes,
            item.FechaInicio,
            item.FechaFin,
            item.Estado,
            item.CerradoEn,
            item.CerradoPorUsuarioId,
            item.Observacion,
            item.TotalIndirectos);

    private static PeriodoCostoDetailDto MapDetail(PeriodoCosto item) =>
        new(
            item.Id,
            item.Anio,
            item.Mes,
            item.FechaInicio,
            item.FechaFin,
            item.Estado,
            item.CerradoEn,
            item.CerradoPorUsuarioId,
            item.Observacion,
            item.TotalIndirectos);
}
