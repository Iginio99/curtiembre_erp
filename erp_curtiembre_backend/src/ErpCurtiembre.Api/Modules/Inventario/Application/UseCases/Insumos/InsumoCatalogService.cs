using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Inventario.Domain.Constants;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Insumos;

public sealed class InsumoCatalogService(
    IInsumoRepository insumoRepository,
    IUnidadMedidaLookupRepository unidadMedidaLookupRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<InsumoListItemDto>> ListAsync(
        InsumoFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await insumoRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<IReadOnlyCollection<InsumoLookupDto>> ListActiveAsync(CancellationToken cancellationToken)
    {
        var items = await insumoRepository.ListActiveAsync(cancellationToken);
        return items.Select(MapLookup).ToArray();
    }

    public async Task<UseCaseResult<InsumoDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var insumo = await insumoRepository.FindByIdAsync(id, cancellationToken);
        return insumo is null
            ? UseCaseResult<InsumoDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el insumo.")
            : UseCaseResult<InsumoDetailDto>.Ok(MapDetail(insumo));
    }

    public async Task<UseCaseResult<InsumoDetailDto>> CreateAsync(
        CreateInsumoRequestDto request,
        long? actorId,
        CancellationToken cancellationToken)
    {
        var codigo = await insumoRepository.GenerateNextCodeAsync(cancellationToken);
        var errors = await ValidateRequestAsync(
            codigo,
            request.Nombre,
            request.TipoBien,
            request.Presentacion,
            request.UnidadMedidaId,
            request.StockMinimo,
            null,
            cancellationToken);

        if (errors.Count > 0)
        {
            return UseCaseResult<InsumoDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await insumoRepository.CreateAsync(
            new Insumo
            {
                Codigo = codigo,
                Nombre = request.Nombre.Trim(),
                TipoBien = request.TipoBien.Trim().ToUpperInvariant(),
                Presentacion = NormalizeNullable(request.Presentacion),
                UnidadMedidaId = request.UnidadMedidaId,
                StockMinimo = request.StockMinimo,
                RequiereLote = request.RequiereLote,
                Activo = true
            },
            actorId,
            cancellationToken);

        var created = await insumoRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<InsumoDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se pudo recuperar el insumo creado.")
            : UseCaseResult<InsumoDetailDto>.Ok(MapDetail(created), "Insumo creado correctamente.");
    }

    public async Task<UseCaseResult<InsumoDetailDto>> UpdateAsync(
        long id,
        UpdateInsumoRequestDto request,
        long? actorId,
        CancellationToken cancellationToken)
    {
        var existing = await insumoRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<InsumoDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el insumo.");
        }

        var errors = await ValidateRequestAsync(
            existing.Codigo,
            request.Nombre,
            request.TipoBien,
            request.Presentacion,
            request.UnidadMedidaId,
            request.StockMinimo,
            id,
            cancellationToken);

        if (errors.Count > 0)
        {
            return UseCaseResult<InsumoDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        await insumoRepository.UpdateAsync(
            new Insumo
            {
                Id = id,
                Codigo = existing.Codigo,
                Nombre = request.Nombre.Trim(),
                TipoBien = request.TipoBien.Trim().ToUpperInvariant(),
                Presentacion = NormalizeNullable(request.Presentacion),
                UnidadMedidaId = request.UnidadMedidaId,
                StockMinimo = request.StockMinimo,
                RequiereLote = request.RequiereLote,
                ActualizadoEn = dateTimeProvider.Now
            },
            actorId,
            cancellationToken);

        var updated = await insumoRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<InsumoDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el insumo actualizado.")
            : UseCaseResult<InsumoDetailDto>.Ok(MapDetail(updated), "Insumo actualizado correctamente.");
    }

    public Task<UseCaseResult<InsumoDetailDto>> ActivateAsync(
        long id,
        long? actorId,
        CancellationToken cancellationToken) =>
        SetActiveAsync(id, true, actorId, "Insumo activado correctamente.", cancellationToken);

    public Task<UseCaseResult<InsumoDetailDto>> InactivateAsync(
        long id,
        long? actorId,
        CancellationToken cancellationToken) =>
        SetActiveAsync(id, false, actorId, "Insumo inactivado correctamente.", cancellationToken);

    private async Task<UseCaseResult<InsumoDetailDto>> SetActiveAsync(
        long id,
        bool activo,
        long? actorId,
        string successMessage,
        CancellationToken cancellationToken)
    {
        var existing = await insumoRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<InsumoDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el insumo.");
        }

        await insumoRepository.SetActiveAsync(id, activo, dateTimeProvider.Now, actorId, cancellationToken);
        var updated = await insumoRepository.FindByIdAsync(id, cancellationToken);

        return updated is null
            ? UseCaseResult<InsumoDetailDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el insumo actualizado.")
            : UseCaseResult<InsumoDetailDto>.Ok(MapDetail(updated), successMessage);
    }

    private async Task<IReadOnlyCollection<string>> ValidateRequestAsync(
        string codigo,
        string nombre,
        string tipoBien,
        string? presentacion,
        long unidadMedidaId,
        decimal stockMinimo,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var normalizedCodigo = codigo.Trim();
        var normalizedNombre = nombre.Trim();
        var normalizedTipoBien = tipoBien.Trim().ToUpperInvariant();
        var normalizedPresentacion = NormalizeNullable(presentacion);

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

        if (!InsumoTipoBienes.Todos.Contains(normalizedTipoBien))
        {
            errors.Add("El tipo de bien no es valido.");
        }

        if (normalizedPresentacion is not null && normalizedPresentacion.Length > 150)
        {
            errors.Add("La presentacion no debe superar 150 caracteres.");
        }

        if (unidadMedidaId <= 0)
        {
            errors.Add("La unidad de medida es obligatoria.");
        }
        else if (!await unidadMedidaLookupRepository.ExistsActiveAsync(unidadMedidaId, cancellationToken))
        {
            errors.Add("La unidad de medida seleccionada no esta activa.");
        }

        if (stockMinimo < 0)
        {
            errors.Add("El stock minimo no puede ser negativo.");
        }

        if (errors.Count == 0 &&
            await insumoRepository.ExistsByCodigoAsync(normalizedCodigo, excludeId, cancellationToken))
        {
            errors.Add("El codigo del insumo ya existe.");
        }

        return errors;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static InsumoListItemDto MapList(Insumo insumo) =>
        new(
            insumo.Id,
            insumo.Codigo,
            insumo.Nombre,
            insumo.TipoBien,
            insumo.Presentacion,
            insumo.UnidadMedidaId,
            insumo.UnidadMedidaCodigo,
            insumo.UnidadMedidaNombre,
            insumo.StockMinimo,
            insumo.CostoPromedioActual,
            insumo.StockActual,
            insumo.RequiereLote,
            insumo.Activo,
            insumo.CreadoEn,
            insumo.ActualizadoEn);

    private static InsumoDetailDto MapDetail(Insumo insumo) =>
        new(
            insumo.Id,
            insumo.Codigo,
            insumo.Nombre,
            insumo.TipoBien,
            insumo.Presentacion,
            insumo.UnidadMedidaId,
            insumo.UnidadMedidaCodigo,
            insumo.UnidadMedidaNombre,
            insumo.StockMinimo,
            insumo.CostoPromedioActual,
            insumo.StockActual,
            insumo.RequiereLote,
            insumo.Activo,
            insumo.CreadoEn,
            insumo.CreadoPorUsuarioId,
            insumo.ActualizadoEn,
            insumo.ActualizadoPorUsuarioId);

    private static InsumoLookupDto MapLookup(Insumo insumo) =>
        new(
            insumo.Id,
            insumo.Codigo,
            insumo.Nombre,
            insumo.TipoBien,
            insumo.UnidadMedidaCodigo,
            insumo.UnidadMedidaNombre,
            insumo.StockActual);
}
