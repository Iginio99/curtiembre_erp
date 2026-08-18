using ErpCurtiembre.Modules.Reportes.Application.Ports;
using ErpCurtiembre.Modules.Reportes.Domain.Entities;

namespace ErpCurtiembre.Modules.Reportes.Infrastructure.Services;

public sealed class ReporteKpiService : IReporteKpiService
{
    private static readonly KpiOperativo[] Items =
    [
        new("KPI-OTIF", "Ordenes entregadas a tiempo", 92.5m, "%"),
        new("KPI-MERMA", "Merma de produccion", 3.2m, "%"),
        new("KPI-MARGEN", "Margen estimado por lote", 18.4m, "%")
    ];

    public Task<IReadOnlyCollection<KpiOperativo>> GetDashboardAsync(CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyCollection<KpiOperativo>>(Items);
}
