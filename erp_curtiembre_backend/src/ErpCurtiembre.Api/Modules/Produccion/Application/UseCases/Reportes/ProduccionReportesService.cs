using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;

namespace ErpCurtiembre.Modules.Produccion.Application.UseCases.Reportes;

public sealed class ProduccionReportesService(IProduccionReportQueryRepository repository)
{
    public Task<IReadOnlyCollection<OrdenesActivasReporteItemDto>> ListActiveOrdersAsync(CancellationToken cancellationToken) =>
        repository.ListActiveOrdersAsync(cancellationToken);

    public Task<IReadOnlyCollection<OrdenesPorClienteReporteItemDto>> ListOrdersByClientAsync(
        OrdenesPorClienteReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        repository.ListOrdersByClientAsync(filters, cancellationToken);

    public Task<IReadOnlyCollection<ConsumoPorProcesoReporteItemDto>> ListConsumptionByProcessAsync(
        ConsumoPorProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        repository.ListConsumptionByProcessAsync(filters, cancellationToken);

    public Task<IReadOnlyCollection<MermaReporteItemDto>> ListMermaAsync(
        MermaReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        repository.ListMermaAsync(filters, cancellationToken);

    public Task<IReadOnlyCollection<TiemposProcesoReporteItemDto>> ListProcessTimesAsync(
        TiemposProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        repository.ListProcessTimesAsync(filters, cancellationToken);

    public Task<IReadOnlyCollection<CostosOrdenReporteItemDto>> ListCostsByOrderAsync(
        CostosOrdenReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        repository.ListCostsByOrderAsync(filters, cancellationToken);

    public Task<IReadOnlyCollection<CostosProcesoReporteItemDto>> ListCostsByProcessAsync(
        CostosOrdenReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        repository.ListCostsByProcessAsync(filters, cancellationToken);
}
