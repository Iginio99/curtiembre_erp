using ErpCurtiembre.Modules.Reportes.Application.DTOs;
using ErpCurtiembre.Modules.Reportes.Application.Ports;

namespace ErpCurtiembre.Modules.Reportes.Application.UseCases;

public sealed class ObtenerDashboardKpiUseCase(IReporteKpiService reporteKpiService)
{
    public async Task<IReadOnlyCollection<KpiDashboardDto>> ExecuteAsync(CancellationToken cancellationToken)
    {
        var items = await reporteKpiService.GetDashboardAsync(cancellationToken);

        return items
            .Select(item => new KpiDashboardDto(
                item.Codigo,
                item.Nombre,
                item.Valor,
                item.UnidadMedida))
            .ToArray();
    }
}
