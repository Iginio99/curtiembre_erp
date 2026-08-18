using ErpCurtiembre.Modules.Reportes.Domain.Entities;

namespace ErpCurtiembre.Modules.Reportes.Application.Ports;

public interface IReporteKpiService
{
    Task<IReadOnlyCollection<KpiOperativo>> GetDashboardAsync(CancellationToken cancellationToken);
}
