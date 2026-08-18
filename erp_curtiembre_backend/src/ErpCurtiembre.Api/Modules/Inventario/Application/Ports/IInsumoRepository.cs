using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IInsumoRepository
{
    Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken);

    Task<Insumo?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(Insumo insumo, long? actorId, CancellationToken cancellationToken);

    Task UpdateAsync(Insumo insumo, long? actorId, CancellationToken cancellationToken);

    Task SetActiveAsync(long id, bool activo, DateTime updatedAt, long? actorId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Insumo>> ListAsync(InsumoFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Insumo>> ListActiveAsync(CancellationToken cancellationToken);
}
