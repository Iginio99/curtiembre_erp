using ErpCurtiembre.Modules.Reportes.Application.DTOs;

namespace ErpCurtiembre.Modules.Reportes.Application.Ports;

public interface IReporteStockBajoService
{
    Task<IReadOnlyCollection<StockBajoReporteDto>> GetLowStockAsync(CancellationToken cancellationToken);
}
