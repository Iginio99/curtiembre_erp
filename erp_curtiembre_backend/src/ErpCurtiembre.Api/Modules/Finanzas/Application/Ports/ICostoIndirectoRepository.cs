using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface ICostoIndirectoRepository
{
    Task<CostoIndirecto?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(CostoIndirecto costoIndirecto, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<CostoIndirecto>> ListAsync(CostoIndirectoFiltersDto filters, CancellationToken cancellationToken);
}
