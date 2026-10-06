using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Application.Support;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.UseCases.Productos;

public sealed class ProductoCatalogoService(IProductoCatalogoRepository repository)
{
    public async Task<IReadOnlyCollection<ProductoCatalogoDto>> ListAsync(bool? activo, CancellationToken cancellationToken) =>
        (await repository.ListAsync(activo, cancellationToken)).Select(Map).ToArray();

    public async Task<UseCaseResult<ProductoCatalogoDto>> CreateAsync(UpsertProductoCatalogoRequestDto request, CancellationToken cancellationToken)
    {
        var error = await ValidateAsync(request, null, cancellationToken);
        if (error is not null) return UseCaseResult<ProductoCatalogoDto>.Fail(ConfiguracionErrorCodes.Validation, error);
        var id = await repository.CreateAsync(ToEntity(request), cancellationToken);
        return UseCaseResult<ProductoCatalogoDto>.Ok(Map((await repository.FindByIdAsync(id, cancellationToken))!), "Producto creado correctamente.");
    }

    public async Task<UseCaseResult<ProductoCatalogoDto>> UpdateAsync(long id, UpsertProductoCatalogoRequestDto request, CancellationToken cancellationToken)
    {
        if (await repository.FindByIdAsync(id, cancellationToken) is null) return UseCaseResult<ProductoCatalogoDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el producto.");
        var error = await ValidateAsync(request, id, cancellationToken);
        if (error is not null) return UseCaseResult<ProductoCatalogoDto>.Fail(ConfiguracionErrorCodes.Validation, error);
        var entity = ToEntity(request);
        entity = new ProductoCatalogo { Id = id, Codigo = entity.Codigo, Tipo = entity.Tipo, Nombre = entity.Nombre, Color = entity.Color, Activo = entity.Activo };
        await repository.UpdateAsync(entity, cancellationToken);
        return UseCaseResult<ProductoCatalogoDto>.Ok(Map((await repository.FindByIdAsync(id, cancellationToken))!), "Producto actualizado correctamente.");
    }

    public async Task<UseCaseResult<ProductoCatalogoDto>> SetActiveAsync(long id, bool activo, CancellationToken cancellationToken)
    {
        var product = await repository.FindByIdAsync(id, cancellationToken);
        if (product is null) return UseCaseResult<ProductoCatalogoDto>.Fail(ConfiguracionErrorCodes.NotFound, "No se encontro el producto.");
        await repository.SetActiveAsync(id, activo, cancellationToken);
        return UseCaseResult<ProductoCatalogoDto>.Ok(Map((await repository.FindByIdAsync(id, cancellationToken))!), activo ? "Producto activado correctamente." : "Producto inactivado correctamente.");
    }

    private async Task<string?> ValidateAsync(UpsertProductoCatalogoRequestDto request, long? excludeId, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Codigo) || string.IsNullOrWhiteSpace(request.Tipo) || string.IsNullOrWhiteSpace(request.Nombre)) return "Código, tipo y nombre son obligatorios.";
        if (await repository.ExistsCodigoAsync(request.Codigo.Trim(), excludeId, cancellationToken)) return "Ya existe un producto con ese código.";
        return null;
    }
    private static ProductoCatalogo ToEntity(UpsertProductoCatalogoRequestDto request) => new() { Codigo = request.Codigo.Trim(), Tipo = request.Tipo.Trim(), Nombre = request.Nombre.Trim(), Color = string.IsNullOrWhiteSpace(request.Color) ? null : request.Color.Trim(), Activo = true };
    private static ProductoCatalogoDto Map(ProductoCatalogo item) => new(item.Id, item.Codigo, item.Tipo, item.Nombre, item.Color, item.Activo, item.CreadoEn);
}
