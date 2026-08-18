using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.Ports;

public interface IAreaRepository
{
    Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken);

    Task<Area?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(Area area, CancellationToken cancellationToken);

    Task UpdateAsync(Area area, CancellationToken cancellationToken);

    Task SetActiveAsync(long id, bool activo, DateTime updatedAt, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Area>> ListAsync(AreaFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Area>> ListActiveAsync(CancellationToken cancellationToken);
}
