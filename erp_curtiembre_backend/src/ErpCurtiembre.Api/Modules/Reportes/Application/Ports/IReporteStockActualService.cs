using ErpCurtiembre.Modules.Reportes.Application.DTOs;

namespace ErpCurtiembre.Modules.Reportes.Application.Ports;

public interface IReporteStockActualService
{
    Task<IReadOnlyCollection<StockActualReporteDto>> GetCurrentStockAsync(
        StockActualReporteFiltersDto filters,
        CancellationToken cancellationToken);
}
