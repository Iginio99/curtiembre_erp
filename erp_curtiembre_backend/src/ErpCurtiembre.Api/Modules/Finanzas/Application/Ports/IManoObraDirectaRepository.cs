using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface IManoObraDirectaRepository
{
    Task<ManoObraDirecta?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(ManoObraDirecta manoObraDirecta, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ManoObraDirecta>> ListAsync(ManoObraDirectaFiltersDto filters, CancellationToken cancellationToken);
}
