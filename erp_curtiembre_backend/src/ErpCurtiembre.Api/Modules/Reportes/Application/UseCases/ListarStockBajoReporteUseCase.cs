using ErpCurtiembre.Modules.Reportes.Application.DTOs;
using ErpCurtiembre.Modules.Reportes.Application.Ports;

namespace ErpCurtiembre.Modules.Reportes.Application.UseCases;

public sealed class ListarStockBajoReporteUseCase(IReporteStockBajoService reporteStockBajoService)
{
    public Task<IReadOnlyCollection<StockBajoReporteDto>> ExecuteAsync(CancellationToken cancellationToken) =>
        reporteStockBajoService.GetLowStockAsync(cancellationToken);
}
