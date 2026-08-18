using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface ILoteRepository
{
    Task<Lote?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(Lote lote, CancellationToken cancellationToken);

    Task UpdateAsync(Lote lote, CancellationToken cancellationToken);

    Task<bool> HasAnyOrderAsync(long loteId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Lote>> ListAsync(LoteFiltersDto filters, CancellationToken cancellationToken);
}
