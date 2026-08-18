using ErpCurtiembre.Modules.Reportes.Application.DTOs;
using ErpCurtiembre.Modules.Reportes.Application.Ports;

namespace ErpCurtiembre.Modules.Reportes.Application.UseCases;

public sealed class ListarConsumoProcesoReporteUseCase(IReporteConsumoProcesoService reporteConsumoProcesoService)
{
    public Task<IReadOnlyCollection<ConsumoProcesoReporteDto>> ExecuteAsync(
        ConsumoProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        reporteConsumoProcesoService.GetProcessConsumptionAsync(filters, cancellationToken);
}
