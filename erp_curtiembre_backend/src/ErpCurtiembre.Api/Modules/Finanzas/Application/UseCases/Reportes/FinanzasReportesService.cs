using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Reportes;

public sealed class FinanzasReportesService(IFinanzasReportQueryService reportQueryService)
{
    public Task<IReadOnlyCollection<ReporteCostoOrdenItemDto>> ListCostoOrdenAsync(CancellationToken cancellationToken) =>
        reportQueryService.ListCostoOrdenAsync(cancellationToken);

    public Task<IReadOnlyCollection<ReporteCostoProcesoItemDto>> ListCostoProcesoAsync(CancellationToken cancellationToken) =>
        reportQueryService.ListCostoProcesoAsync(cancellationToken);

    public Task<IReadOnlyCollection<ReporteCostoClienteItemDto>> ListCostoClienteAsync(CancellationToken cancellationToken) =>
        reportQueryService.ListCostoClienteAsync(cancellationToken);

    public Task<IReadOnlyCollection<ReporteIndirectoPeriodoItemDto>> ListIndirectosPeriodoAsync(CancellationToken cancellationToken) =>
        reportQueryService.ListIndirectosPeriodoAsync(cancellationToken);

    public Task<IReadOnlyCollection<ReporteRentabilidadItemDto>> ListRentabilidadAsync(CancellationToken cancellationToken) =>
        reportQueryService.ListRentabilidadAsync(cancellationToken);

    public Task<IReadOnlyCollection<ReportePrecioSugeridoItemDto>> ListPrecioSugeridoAsync(CancellationToken cancellationToken) =>
        reportQueryService.ListPrecioSugeridoAsync(cancellationToken);
}
