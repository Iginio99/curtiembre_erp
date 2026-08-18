using ErpCurtiembre.Modules.Finanzas.Application.DTOs;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface IFinanzasReportQueryService
{
    Task<IReadOnlyCollection<ReporteCostoOrdenItemDto>> ListCostoOrdenAsync(CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ReporteCostoProcesoItemDto>> ListCostoProcesoAsync(CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ReporteCostoClienteItemDto>> ListCostoClienteAsync(CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ReporteIndirectoPeriodoItemDto>> ListIndirectosPeriodoAsync(CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ReporteRentabilidadItemDto>> ListRentabilidadAsync(CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ReportePrecioSugeridoItemDto>> ListPrecioSugeridoAsync(CancellationToken cancellationToken);
}
