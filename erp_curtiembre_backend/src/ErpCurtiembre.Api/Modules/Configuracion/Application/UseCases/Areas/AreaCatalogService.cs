using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Application.Support;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Configuracion.Application.UseCases.Areas;

public sealed class AreaCatalogService(
    IAreaRepository areaRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<AreaListItemDto>> ListAsync(AreaFiltersDto filters, CancellationToken cancellationToken)
    {
        var items = await areaRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<IReadOnlyCollection<AreaListItemDto>> ListActiveAsync(CancellationToken cancellationToken)
    {
        var items = await areaRepository.ListActiveAsync(cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<AreaDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var area = await areaRepository.FindByIdAsync(id, cancellationToken);
        return area is null
            ? UseCaseResult<AreaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el area.")
            : UseCaseResult<AreaDetailDto>.Ok(MapDetail(area));
    }

    public async Task<UseCaseResult<AreaDetailDto>> CreateAsync(CreateAreaRequestDto request, CancellationToken cancellationToken)
    {
        var errors = await ValidateRequestAsync(request.Codigo, request.Nombre, request.Descripcion, null, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<AreaDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await areaRepository.CreateAsync(
            new Area
            {
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                Descripcion = NormalizeNullable(request.Descripcion),
                Activo = true
            },
            cancellationToken);

        var created = await areaRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<AreaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se pudo recuperar el area creada.")
            : UseCaseResult<AreaDetailDto>.Ok(MapDetail(created), "Area creada correctamente.");
    }

    public async Task<UseCaseResult<AreaDetailDto>> UpdateAsync(long id, UpdateAreaRequestDto request, CancellationToken cancellationToken)
    {
        var existing = await areaRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<AreaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el area.");
        }

        var errors = await ValidateRequestAsync(request.Codigo, request.Nombre, request.Descripcion, id, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<AreaDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        await areaRepository.UpdateAsync(
            new Area
            {
                Id = id,
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                Descripcion = NormalizeNullable(request.Descripcion),
                ActualizadoEn = dateTimeProvider.Now
            },
            cancellationToken);

        var updated = await areaRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<AreaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el area actualizada.")
            : UseCaseResult<AreaDetailDto>.Ok(MapDetail(updated), "Area actualizada correctamente.");
    }

    public Task<UseCaseResult<AreaDetailDto>> ActivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, true, "Area activada correctamente.", cancellationToken);

    public Task<UseCaseResult<AreaDetailDto>> InactivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, false, "Area inactivada correctamente.", cancellationToken);

    private async Task<UseCaseResult<AreaDetailDto>> SetActiveAsync(
        long id,
        bool activo,
        string successMessage,
        CancellationToken cancellationToken)
    {
        var existing = await areaRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<AreaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el area.");
        }

        await areaRepository.SetActiveAsync(id, activo, dateTimeProvider.Now, cancellationToken);
        var updated = await areaRepository.FindByIdAsync(id, cancellationToken);

        return updated is null
            ? UseCaseResult<AreaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el area actualizada.")
            : UseCaseResult<AreaDetailDto>.Ok(MapDetail(updated), successMessage);
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
        else if (normalizedNombre.Length > 100)
        {
            errors.Add("El nombre no debe superar 100 caracteres.");
        }

        var normalizedDescripcion = NormalizeNullable(descripcion);
        if (normalizedDescripcion is not null && normalizedDescripcion.Length > 250)
        {
            errors.Add("La descripcion no debe superar 250 caracteres.");
        }

        if (errors.Count == 0 &&
            await areaRepository.ExistsByCodigoAsync(normalizedCodigo, excludeId, cancellationToken))
        {
            errors.Add("El codigo del area ya existe.");
        }

        return errors;
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static AreaListItemDto MapList(Area area) =>
        new(area.Id, area.Codigo, area.Nombre, area.Descripcion, area.Activo, area.CreadoEn, area.ActualizadoEn);

    private static AreaDetailDto MapDetail(Area area) =>
        new(area.Id, area.Codigo, area.Nombre, area.Descripcion, area.Activo, area.CreadoEn, area.ActualizadoEn);
}
