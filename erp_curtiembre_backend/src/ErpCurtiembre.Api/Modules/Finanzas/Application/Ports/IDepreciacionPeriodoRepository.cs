using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface IDepreciacionPeriodoRepository
{
    Task<DepreciacionPeriodo?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<DepreciacionPeriodo>> ListAsync(DepreciacionPeriodoFiltersDto filters, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<long>> ListRegisteredAssetIdsByPeriodAsync(long periodoCostoId, CancellationToken cancellationToken);

    Task CreateManyAsync(IReadOnlyCollection<DepreciacionPeriodo> depreciaciones, CancellationToken cancellationToken);
}
