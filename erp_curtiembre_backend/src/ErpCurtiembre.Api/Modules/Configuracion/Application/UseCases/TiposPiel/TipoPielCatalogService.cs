using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Application.Support;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.UseCases.TiposPiel;

public sealed class TipoPielCatalogService(ITipoPielRepository tipoPielRepository)
{
    public async Task<IReadOnlyCollection<TipoPielListItemDto>> ListAsync(
        TipoPielFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await tipoPielRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<IReadOnlyCollection<TipoPielListItemDto>> ListActiveAsync(CancellationToken cancellationToken)
    {
        var items = await tipoPielRepository.ListActiveAsync(cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<TipoPielDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var tipoPiel = await tipoPielRepository.FindByIdAsync(id, cancellationToken);
        return tipoPiel is null
            ? UseCaseResult<TipoPielDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el tipo de piel.")
            : UseCaseResult<TipoPielDetailDto>.Ok(MapDetail(tipoPiel));
    }

    public async Task<UseCaseResult<TipoPielDetailDto>> CreateAsync(
        CreateTipoPielRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = await ValidateRequestAsync(request.Codigo, request.Nombre, request.Descripcion, null, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<TipoPielDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await tipoPielRepository.CreateAsync(
            new TipoPiel
            {
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                Descripcion = NormalizeNullable(request.Descripcion),
                Activo = true
            },
            cancellationToken);

        var created = await tipoPielRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<TipoPielDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se pudo recuperar el tipo de piel creado.")
            : UseCaseResult<TipoPielDetailDto>.Ok(MapDetail(created), "Tipo de piel creado correctamente.");
    }

    public async Task<UseCaseResult<TipoPielDetailDto>> UpdateAsync(
        long id,
        UpdateTipoPielRequestDto request,
        CancellationToken cancellationToken)
    {
        var existing = await tipoPielRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<TipoPielDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el tipo de piel.");
        }

        var errors = await ValidateRequestAsync(request.Codigo, request.Nombre, request.Descripcion, id, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<TipoPielDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        await tipoPielRepository.UpdateAsync(
            new TipoPiel
            {
                Id = id,
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                Descripcion = NormalizeNullable(request.Descripcion)
            },
            cancellationToken);

        var updated = await tipoPielRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<TipoPielDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el tipo de piel actualizado.")
            : UseCaseResult<TipoPielDetailDto>.Ok(MapDetail(updated), "Tipo de piel actualizado correctamente.");
    }

    public Task<UseCaseResult<TipoPielDetailDto>> ActivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, true, "Tipo de piel activado correctamente.", cancellationToken);

    public Task<UseCaseResult<TipoPielDetailDto>> InactivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, false, "Tipo de piel inactivado correctamente.", cancellationToken);

    private async Task<UseCaseResult<TipoPielDetailDto>> SetActiveAsync(
        long id,
        bool activo,
        string successMessage,
        CancellationToken cancellationToken)
    {
        var existing = await tipoPielRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<TipoPielDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el tipo de piel.");
        }

        await tipoPielRepository.SetActiveAsync(id, activo, cancellationToken);
        var updated = await tipoPielRepository.FindByIdAsync(id, cancellationToken);

        return updated is null
            ? UseCaseResult<TipoPielDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el tipo de piel actualizado.")
            : UseCaseResult<TipoPielDetailDto>.Ok(MapDetail(updated), successMessage);
    }

    private async Task<IReadOnlyCollection<string>> ValidateRequestAsync(
        string codigo,
        string nombre,
        string? descripcion,
        long? excludeId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        var normalizedCodigo = codigo.Trim();
        var normalizedNombre = nombre.Trim();
        var normalizedDescripcion = NormalizeNullable(descripcion);

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
        else if (normalizedNombre.Length > 120)
        {
            errors.Add("El nombre no debe superar 120 caracteres.");
        }

        if (normalizedDescripcion is not null && normalizedDescripcion.Length > 250)
        {
            errors.Add("La descripcion no debe superar 250 caracteres.");
        }

        if (errors.Count == 0 &&
            await tipoPielRepository.ExistsByCodigoAsync(normalizedCodigo, excludeId, cancellationToken))
        {
            errors.Add("El codigo del tipo de piel ya existe.");
        }

        return errors;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static TipoPielListItemDto MapList(TipoPiel tipoPiel) =>
        new(tipoPiel.Id, tipoPiel.Codigo, tipoPiel.Nombre, tipoPiel.Descripcion, tipoPiel.Activo, tipoPiel.CreadoEn);

    private static TipoPielDetailDto MapDetail(TipoPiel tipoPiel) =>
        new(tipoPiel.Id, tipoPiel.Codigo, tipoPiel.Nombre, tipoPiel.Descripcion, tipoPiel.Activo, tipoPiel.CreadoEn);
}
