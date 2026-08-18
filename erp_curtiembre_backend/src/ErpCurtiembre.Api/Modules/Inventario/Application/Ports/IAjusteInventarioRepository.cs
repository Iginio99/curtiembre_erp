using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IAjusteInventarioRepository
{
    Task<long> RegisterAsync(AjusteInventarioRegistration registration, CancellationToken cancellationToken);

    Task<AjusteInventario?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<AjusteInventarioDetalle>> ListDetailsAsync(long ajusteId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<AjusteInventario>> ListAsync(AjusteInventarioFiltersDto filters, CancellationToken cancellationToken);
}
