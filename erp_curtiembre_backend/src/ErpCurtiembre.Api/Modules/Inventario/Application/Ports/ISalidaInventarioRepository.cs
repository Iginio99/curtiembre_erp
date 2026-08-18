using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface ISalidaInventarioRepository
{
    Task<long> RegisterAsync(SalidaInventarioRegistration registration, CancellationToken cancellationToken);

    Task<SalidaInventario?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<SalidaInventarioDetalle>> ListDetailsAsync(long salidaId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<SalidaInventario>> ListAsync(SalidaInventarioFiltersDto filters, CancellationToken cancellationToken);
}
