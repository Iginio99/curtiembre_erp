using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Application.Support;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.UseCases.UnidadesMedida;

public sealed class UnidadMedidaCatalogService(IUnidadMedidaRepository unidadMedidaRepository)
{
    public async Task<IReadOnlyCollection<UnidadMedidaListItemDto>> ListAsync(
        UnidadMedidaFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await unidadMedidaRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<IReadOnlyCollection<UnidadMedidaListItemDto>> ListActiveAsync(CancellationToken cancellationToken)
    {
        var items = await unidadMedidaRepository.ListActiveAsync(cancellationToken);
        return items.Select(MapList).ToArray();
    }

    public async Task<UseCaseResult<UnidadMedidaDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var unidad = await unidadMedidaRepository.FindByIdAsync(id, cancellationToken);
        return unidad is null
            ? UseCaseResult<UnidadMedidaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la unidad de medida.")
            : UseCaseResult<UnidadMedidaDetailDto>.Ok(MapDetail(unidad));
    }

    public async Task<UseCaseResult<UnidadMedidaDetailDto>> CreateAsync(
        CreateUnidadMedidaRequestDto request,
        CancellationToken cancellationToken)
    {
        var errors = await ValidateRequestAsync(request.Codigo, request.Nombre, null, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<UnidadMedidaDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        var id = await unidadMedidaRepository.CreateAsync(
            new UnidadMedida
            {
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                PermiteDecimales = request.PermiteDecimales,
                Activo = true
            },
            cancellationToken);

        var created = await unidadMedidaRepository.FindByIdAsync(id, cancellationToken);
        return created is null
            ? UseCaseResult<UnidadMedidaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se pudo recuperar la unidad creada.")
            : UseCaseResult<UnidadMedidaDetailDto>.Ok(MapDetail(created), "Unidad de medida creada correctamente.");
    }

    public async Task<UseCaseResult<UnidadMedidaDetailDto>> UpdateAsync(
        long id,
        UpdateUnidadMedidaRequestDto request,
        CancellationToken cancellationToken)
    {
        var existing = await unidadMedidaRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<UnidadMedidaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la unidad de medida.");
        }

        var errors = await ValidateRequestAsync(request.Codigo, request.Nombre, id, cancellationToken);
        if (errors.Count > 0)
        {
            return UseCaseResult<UnidadMedidaDetailDto>.Fail(ConfiguracionErrorCodes.Validation, string.Join(" ", errors));
        }

        await unidadMedidaRepository.UpdateAsync(
            new UnidadMedida
            {
                Id = id,
                Codigo = request.Codigo.Trim(),
                Nombre = request.Nombre.Trim(),
                PermiteDecimales = request.PermiteDecimales
            },
            cancellationToken);

        var updated = await unidadMedidaRepository.FindByIdAsync(id, cancellationToken);
        return updated is null
            ? UseCaseResult<UnidadMedidaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la unidad actualizada.")
            : UseCaseResult<UnidadMedidaDetailDto>.Ok(MapDetail(updated), "Unidad de medida actualizada correctamente.");
    }

    public Task<UseCaseResult<UnidadMedidaDetailDto>> ActivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, true, "Unidad de medida activada correctamente.", cancellationToken);

    public Task<UseCaseResult<UnidadMedidaDetailDto>> InactivateAsync(long id, CancellationToken cancellationToken) =>
        SetActiveAsync(id, false, "Unidad de medida inactivada correctamente.", cancellationToken);

    private async Task<UseCaseResult<UnidadMedidaDetailDto>> SetActiveAsync(
        long id,
        bool activo,
        string successMessage,
        CancellationToken cancellationToken)
    {
        var existing = await unidadMedidaRepository.FindByIdAsync(id, cancellationToken);
        if (existing is null)
        {
            return UseCaseResult<UnidadMedidaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la unidad de medida.");
        }

        await unidadMedidaRepository.SetActiveAsync(id, activo, cancellationToken);
        var updated = await unidadMedidaRepository.FindByIdAsync(id, cancellationToken);

        return updated is null
            ? UseCaseResult<UnidadMedidaDetailDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro la unidad actualizada.")
            : UseCaseResult<UnidadMedidaDetailDto>.Ok(MapDetail(updated), successMessage);
    }

    private async Task<IReadOnlyCollection<string>> ValidateRequestAsync(
        string codigo,
        string nombre,
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
        else if (normalizedCodigo.Length > 20)
        {
            errors.Add("El codigo no debe superar 20 caracteres.");
        }

        if (string.IsNullOrWhiteSpace(normalizedNombre))
        {
            errors.Add("El nombre es obligatorio.");
        }
        else if (normalizedNombre.Length > 80)
        {
            errors.Add("El nombre no debe superar 80 caracteres.");
        }

        if (errors.Count == 0 &&
            await unidadMedidaRepository.ExistsByCodigoAsync(normalizedCodigo, excludeId, cancellationToken))
        {
            errors.Add("El codigo de la unidad de medida ya existe.");
        }

        return errors;
    }

    private static UnidadMedidaListItemDto MapList(UnidadMedida unidadMedida) =>
        new(
            unidadMedida.Id,
            unidadMedida.Codigo,
            unidadMedida.Nombre,
            unidadMedida.PermiteDecimales,
            unidadMedida.Activo,
            unidadMedida.CreadoEn);

    private static UnidadMedidaDetailDto MapDetail(UnidadMedida unidadMedida) =>
        new(
            unidadMedida.Id,
            unidadMedida.Codigo,
            unidadMedida.Nombre,
            unidadMedida.PermiteDecimales,
            unidadMedida.Activo,
            unidadMedida.CreadoEn);
}
