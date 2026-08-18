using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IInventarioFisicoRepository
{
    Task<long> CreateAsync(InventarioFisicoRegistration registration, CancellationToken cancellationToken);

    Task RegisterCountsAsync(
        long inventarioFisicoId,
        IReadOnlyCollection<InventarioFisicoCountRegistrationDetail> details,
        CancellationToken cancellationToken);

    Task CloseAsync(InventarioFisicoCloseRegistration registration, CancellationToken cancellationToken);

    Task<InventarioFisico?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<InventarioFisicoDetalle>> ListDetailsAsync(long inventarioFisicoId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<InventarioFisico>> ListAsync(InventarioFisicoFiltersDto filters, CancellationToken cancellationToken);
}
