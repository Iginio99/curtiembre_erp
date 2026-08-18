using ErpCurtiembre.Modules.Reportes.Application.DTOs;

namespace ErpCurtiembre.Modules.Reportes.Application.Ports;

public interface IReporteKardexConsultaService
{
    Task<IReadOnlyCollection<KardexReporteDto>> GetKardexAsync(
        KardexReporteFiltersDto filters,
        CancellationToken cancellationToken);
}
