using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IProveedorRepository
{
    Task<bool> ExistsByDocumentoAsync(string rucDocumento, long? excludeId, CancellationToken cancellationToken);

    Task<bool> HasAnyOrderAsync(long proveedorId, CancellationToken cancellationToken);

    Task<Proveedor?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(Proveedor proveedor, CancellationToken cancellationToken);

    Task UpdateAsync(Proveedor proveedor, CancellationToken cancellationToken);

    Task SetActiveAsync(long id, bool activo, DateTime updatedAt, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Proveedor>> ListAsync(ProveedorFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Proveedor>> ListActiveAsync(CancellationToken cancellationToken);
}
