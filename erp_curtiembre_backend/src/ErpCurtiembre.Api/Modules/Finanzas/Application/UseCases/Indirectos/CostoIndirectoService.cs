using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Indirectos;

public sealed class CostoIndirectoService(
    ICostoIndirectoRepository costoIndirectoRepository,
    IPeriodoCostoRepository periodoCostoRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<CostoIndirectoListItemDto>> ListAsync(
        CostoIndirectoFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await costoIndirectoRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<CostoIndirectoDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var item = await costoIndirectoRepository.FindByIdAsync(id, cancellationToken);
        return item is null
            ? UseCaseResult<CostoIndirectoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el costo indirecto.")
            : UseCaseResult<CostoIndirectoDetailDto>.Ok(MapDetail(item));
    }

    public async Task<UseCaseResult<CostoIndirectoDetailDto>> CreateAsync(
        long actorId,
        CreateCostoIndirectoRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var periodo = await periodoCostoRepository.FindByIdAsync(request.PeriodoCostoId, cancellationToken);
        if (periodo is null)
        {
            errors.Add("El periodo de costo indicado no existe.");
        }
        else if (periodo.Estado != "ABIERTO")
        {
            errors.Add("Solo se pueden registrar costos indirectos en periodos abiertos.");
        }

        var tipoCosto = request.TipoCosto.Trim();
        if (string.IsNullOrWhiteSpace(tipoCosto))
        {
            errors.Add("El tipo de costo es obligatorio.");
        }
        else if (tipoCosto.Length > 80)
        {
            errors.Add("El tipo de costo no debe superar 80 caracteres.");
        }

        var descripcion = NormalizeNullable(request.Descripcion);
        if (descripcion is not null && descripcion.Length > 300)
        {
            errors.Add("La descripcion no debe superar 300 caracteres.");
        }

        if (request.Monto < 0)
        {
            errors.Add("El monto no puede ser negativo.");
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<CostoIndirectoDetailDto>.Fail(FinanzasErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await costoIndirectoRepository.CreateAsync(
            new CostoIndirecto
            {
                PeriodoCostoId = request.PeriodoCostoId,
                TipoCosto = tipoCosto,
                Descripcion = descripcion,
                Monto = request.Monto,
                RegistradoEn = dateTimeProvider.Now,
                RegistradoPorUsuarioId = actorId
            },
            cancellationToken);

        var created = await costoIndirectoRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<CostoIndirectoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el costo indirecto creado.")
            : UseCaseResult<CostoIndirectoDetailDto>.Ok(MapDetail(created), "Costo indirecto registrado correctamente.");
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static CostoIndirectoListItemDto MapList(CostoIndirecto item) =>
        new(
            item.Id,
            item.PeriodoCostoId,
            item.PeriodoAnio,
            item.PeriodoMes,
            item.PeriodoEstado,
            item.TipoCosto,
            item.Descripcion,
            item.Monto,
            item.RegistradoEn,
            item.RegistradoPorUsuarioId);

    private static CostoIndirectoDetailDto MapDetail(CostoIndirecto item) =>
        new(
            item.Id,
            item.PeriodoCostoId,
            item.PeriodoAnio,
            item.PeriodoMes,
            item.PeriodoEstado,
            item.TipoCosto,
            item.Descripcion,
            item.Monto,
            item.RegistradoEn,
            item.RegistradoPorUsuarioId);
}
