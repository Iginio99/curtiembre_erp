using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IKardexRepository
{
    Task<IReadOnlyCollection<KardexMovimiento>> ListAsync(KardexFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<KardexMovimiento>> ListByInsumoAsync(long insumoId, KardexFiltersDto filters, CancellationToken cancellationToken);
}
