using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface IFormulaConsumptionLookupRepository
{
    Task<IReadOnlyCollection<FormulaConsumptionDetail>> ListCurrentDetailsByProcessIdsAsync(
        IReadOnlyCollection<long> processIds,
        DateTime today,
        CancellationToken cancellationToken);
}
