using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Activos;

public sealed class ActivoDepreciableService(IActivoDepreciableRepository activoDepreciableRepository)
{
    public async Task<IReadOnlyCollection<ActivoDepreciableListItemDto>> ListAsync(
        ActivoDepreciableFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await activoDepreciableRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<ActivoDepreciableDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var item = await activoDepreciableRepository.FindByIdAsync(id, cancellationToken);
        return item is null
            ? UseCaseResult<ActivoDepreciableDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el activo depreciable.")
            : UseCaseResult<ActivoDepreciableDetailDto>.Ok(MapDetail(item));
    }

    public async Task<UseCaseResult<ActivoDepreciableDetailDto>> CreateAsync(
        CreateActivoDepreciableRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = await ValidateAsync(
            request.Codigo,
            request.Nombre,
            request.ValorCompra,
            request.FechaCompra,
            request.VidaUtilMeses,
            request.ValorResidual,
            null,
            cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<ActivoDepreciableDetailDto>.Fail(FinanzasErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await activoDepreciableRepository.CreateAsync(
            new ActivoDepreciable
            {
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                ValorCompra = request.ValorCompra,
                FechaCompra = request.FechaCompra.Date,
                VidaUtilMeses = request.VidaUtilMeses,
                ValorResidual = request.ValorResidual,
                Activo = request.Activo
            },
            cancellationToken);

        var created = await activoDepreciableRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<ActivoDepreciableDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el activo creado.")
            : UseCaseResult<ActivoDepreciableDetailDto>.Ok(MapDetail(created), "Activo depreciable creado correctamente.");
    }

    public async Task<UseCaseResult<ActivoDepreciableDetailDto>> UpdateAsync(
        long id,
        UpdateActivoDepreciableRequestDto request,
        CancellationToken cancellationToken)
    {
        var existing = await activoDepreciableRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<ActivoDepreciableDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el activo depreciable.");
        }

        var errors = await ValidateAsync(
            request.Codigo,
            request.Nombre,
            request.ValorCompra,
            request.FechaCompra,
            request.VidaUtilMeses,
            request.ValorResidual,
            id,
            cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<ActivoDepreciableDetailDto>.Fail(FinanzasErrorCodes.Validation, string.Join(" ", errors));
        }

        await activoDepreciableRepository.UpdateAsync(
            new ActivoDepreciable
            {
                Id = id,
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                ValorCompra = request.ValorCompra,
                FechaCompra = request.FechaCompra.Date,
                VidaUtilMeses = request.VidaUtilMeses,
                ValorResidual = request.ValorResidual,
                Activo = request.Activo
            },
            cancellationToken);

        var updated = await activoDepreciableRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<ActivoDepreciableDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el activo actualizado.")
            : UseCaseResult<ActivoDepreciableDetailDto>.Ok(MapDetail(updated), "Activo depreciable actualizado correctamente.");
    }

    private async Task<IReadOnlyCollection<string>> ValidateAsync(
        string codigo,
        string nombre,
        decimal valorCompra,
        DateTime fechaCompra,
        int vidaUtilMeses,
        decimal valorResidual,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var normalizedCodigo = codigo.Trim();
        var normalizedNombre = nombre.Trim();

        if (string.IsNullOrWhiteSpace(normalizedCodigo))
        {
            errors.Add("El codigo es obligatorio.");
        }
        else if (normalizedCodigo.Length > 50)
        {
            errors.Add("El codigo no debe superar 50 caracteres.");
        }

        if (string.IsNullOrWhiteSpace(normalizedNombre))
        {
            errors.Add("El nombre es obligatorio.");
        }
        else if (normalizedNombre.Length > 150)
        {
            errors.Add("El nombre no debe superar 150 caracteres.");
        }

        if (valorCompra < 0)
        {
            errors.Add("El valor de compra no puede ser negativo.");
        }

        if (valorResidual < 0)
        {
            errors.Add("El valor residual no puede ser negativo.");
        }

        if (valorResidual > valorCompra)
        {
            errors.Add("El valor residual no puede ser mayor al valor de compra.");
        }

        if (vidaUtilMeses <= 0)
        {
            errors.Add("La vida util en meses debe ser mayor a cero.");
        }

        if (fechaCompra == default)
        {
            errors.Add("La fecha de compra es obligatoria.");
        }

        if (errors.Count == 0 &&
            await activoDepreciableRepository.ExistsByCodigoAsync(normalizedCodigo, excludeId, cancellationToken))
        {
            errors.Add("El codigo del activo ya existe.");
        }

        return errors;
    }

    private static ActivoDepreciableListItemDto MapList(ActivoDepreciable item) =>
        new(
            item.Id,
            item.Codigo,
            item.Nombre,
            item.ValorCompra,
            item.FechaCompra,
            item.VidaUtilMeses,
            item.ValorResidual,
            item.Activo,
            item.CreadoEn);

    private static ActivoDepreciableDetailDto MapDetail(ActivoDepreciable item) =>
        new(
            item.Id,
            item.Codigo,
            item.Nombre,
            item.ValorCompra,
            item.FechaCompra,
            item.VidaUtilMeses,
            item.ValorResidual,
            item.Activo,
            item.CreadoEn,
            CalculateMonthlyDepreciation(item));

    private static decimal CalculateMonthlyDepreciation(ActivoDepreciable item) =>
        item.VidaUtilMeses <= 0
            ? 0
            : decimal.Round((item.ValorCompra - item.ValorResidual) / item.VidaUtilMeses, 2, MidpointRounding.AwayFromZero);
}
