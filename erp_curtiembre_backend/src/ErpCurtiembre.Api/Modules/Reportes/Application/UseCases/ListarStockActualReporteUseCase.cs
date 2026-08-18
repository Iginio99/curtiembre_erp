using ErpCurtiembre.Modules.Reportes.Application.DTOs;
using ErpCurtiembre.Modules.Reportes.Application.Ports;

namespace ErpCurtiembre.Modules.Reportes.Application.UseCases;

public sealed class ListarStockActualReporteUseCase(IReporteStockActualService reporteStockActualService)
{
    public Task<IReadOnlyCollection<StockActualReporteDto>> ExecuteAsync(
        StockActualReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        reporteStockActualService.GetCurrentStockAsync(filters, cancellationToken);
}
