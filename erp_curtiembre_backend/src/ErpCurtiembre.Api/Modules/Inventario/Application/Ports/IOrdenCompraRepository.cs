using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IOrdenCompraRepository
{
    Task<long> CreateAsync(OrdenCompraRegistration registration, CancellationToken cancellationToken);

    Task<OrdenCompra?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<OrdenCompraDetalle>> ListDetailsAsync(long ordenCompraId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<OrdenCompra>> ListAsync(OrdenCompraFiltersDto filters, CancellationToken cancellationToken);

    Task SetApprovedAsync(long id, DateTime approvedAt, long actorId, CancellationToken cancellationToken);

    Task SetRejectedAsync(long id, string motivo, DateTime updatedAt, long actorId, CancellationToken cancellationToken);

    Task SetCancelledAsync(long id, string motivo, DateTime updatedAt, long actorId, CancellationToken cancellationToken);
}
