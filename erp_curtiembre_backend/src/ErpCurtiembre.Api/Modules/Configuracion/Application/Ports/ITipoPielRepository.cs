using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.Ports;

public interface ITipoPielRepository
{
    Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken);

    Task<TipoPiel?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(TipoPiel tipoPiel, CancellationToken cancellationToken);

    Task UpdateAsync(TipoPiel tipoPiel, CancellationToken cancellationToken);

    Task SetActiveAsync(long id, bool activo, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<TipoPiel>> ListAsync(TipoPielFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<TipoPiel>> ListActiveAsync(CancellationToken cancellationToken);
}
