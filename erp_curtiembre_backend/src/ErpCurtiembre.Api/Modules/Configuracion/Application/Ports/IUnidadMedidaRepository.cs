using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.Ports;

public interface IUnidadMedidaRepository
{
    Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken);

    Task<UnidadMedida?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(UnidadMedida unidadMedida, CancellationToken cancellationToken);

    Task UpdateAsync(UnidadMedida unidadMedida, CancellationToken cancellationToken);

    Task SetActiveAsync(long id, bool activo, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<UnidadMedida>> ListAsync(UnidadMedidaFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<UnidadMedida>> ListActiveAsync(CancellationToken cancellationToken);
}
