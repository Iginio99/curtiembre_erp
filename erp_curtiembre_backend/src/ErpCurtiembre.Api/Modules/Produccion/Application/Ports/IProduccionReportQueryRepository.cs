using ErpCurtiembre.Modules.Produccion.Application.DTOs;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface IProduccionReportQueryRepository
{
    Task<IReadOnlyCollection<OrdenesActivasReporteItemDto>> ListActiveOrdersAsync(CancellationToken cancellationToken);

    Task<IReadOnlyCollection<OrdenesPorClienteReporteItemDto>> ListOrdersByClientAsync(
        OrdenesPorClienteReporteFiltersDto filters,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ConsumoPorProcesoReporteItemDto>> ListConsumptionByProcessAsync(
        ConsumoPorProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<MermaReporteItemDto>> ListMermaAsync(
        MermaReporteFiltersDto filters,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<TiemposProcesoReporteItemDto>> ListProcessTimesAsync(
        TiemposProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<CostosOrdenReporteItemDto>> ListCostsByOrderAsync(
        CostosOrdenReporteFiltersDto filters,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<CostosProcesoReporteItemDto>> ListCostsByProcessAsync(
        CostosOrdenReporteFiltersDto filters,
        CancellationToken cancellationToken);
}
