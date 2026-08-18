using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface IClienteRepository
{
    Task<bool> ExistsByDocumentoAsync(string rucDocumento, long? excludeId, CancellationToken cancellationToken);

    Task<Cliente?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(Cliente cliente, CancellationToken cancellationToken);

    Task UpdateAsync(Cliente cliente, CancellationToken cancellationToken);

    Task SetActiveAsync(long id, bool activo, DateTime updatedAt, CancellationToken cancellationToken);

    Task<bool> HasAnyLoteAsync(long clienteId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Cliente>> ListAsync(ClienteFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Cliente>> ListActiveAsync(CancellationToken cancellationToken);
}
