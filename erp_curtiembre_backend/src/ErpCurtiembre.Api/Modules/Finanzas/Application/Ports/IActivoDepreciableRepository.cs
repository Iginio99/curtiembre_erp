using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface IActivoDepreciableRepository
{
    Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken);

    Task<ActivoDepreciable?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> CreateAsync(ActivoDepreciable activo, CancellationToken cancellationToken);

    Task UpdateAsync(ActivoDepreciable activo, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ActivoDepreciable>> ListAsync(ActivoDepreciableFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ActivoDepreciable>> ListEligibleForPeriodAsync(DateTime fechaFinPeriodo, CancellationToken cancellationToken);
}
