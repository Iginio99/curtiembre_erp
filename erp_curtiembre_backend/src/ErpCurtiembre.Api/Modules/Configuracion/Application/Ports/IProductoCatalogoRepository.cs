using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.Ports;

public interface IProductoCatalogoRepository
{
    Task<IReadOnlyCollection<ProductoCatalogo>> ListAsync(bool? activo, CancellationToken cancellationToken);
    Task<ProductoCatalogo?> FindByIdAsync(long id, CancellationToken cancellationToken);
    Task<bool> ExistsCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken);
    Task<long> CreateAsync(ProductoCatalogo producto, CancellationToken cancellationToken);
    Task UpdateAsync(ProductoCatalogo producto, CancellationToken cancellationToken);
    Task SetActiveAsync(long id, bool activo, CancellationToken cancellationToken);
}
