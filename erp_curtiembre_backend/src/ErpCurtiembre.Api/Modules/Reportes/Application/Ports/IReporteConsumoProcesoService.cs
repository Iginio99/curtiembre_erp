using ErpCurtiembre.Modules.Reportes.Application.DTOs;

namespace ErpCurtiembre.Modules.Reportes.Application.Ports;

public interface IReporteConsumoProcesoService
{
    Task<IReadOnlyCollection<ConsumoProcesoReporteDto>> GetProcessConsumptionAsync(
        ConsumoProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken);
}
