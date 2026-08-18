using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IStockRepository
{
    Task<IReadOnlyCollection<StockActual>> ListAsync(StockFiltersDto filters, CancellationToken cancellationToken);

    Task<StockActual?> GetByInsumoIdAsync(long insumoId, CancellationToken cancellationToken);
}
