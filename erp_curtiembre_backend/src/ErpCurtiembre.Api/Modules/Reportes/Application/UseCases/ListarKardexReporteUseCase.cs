using ErpCurtiembre.Modules.Reportes.Application.DTOs;
using ErpCurtiembre.Modules.Reportes.Application.Ports;

namespace ErpCurtiembre.Modules.Reportes.Application.UseCases;

public sealed class ListarKardexReporteUseCase(IReporteKardexConsultaService reporteKardexConsultaService)
{
    public Task<IReadOnlyCollection<KardexReporteDto>> ExecuteAsync(
        KardexReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        reporteKardexConsultaService.GetKardexAsync(filters, cancellationToken);
}
