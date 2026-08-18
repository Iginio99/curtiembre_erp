using ErpCurtiembre.Modules.Reportes.Application.DTOs;
using ErpCurtiembre.Modules.Reportes.Application.Ports;

namespace ErpCurtiembre.Modules.Reportes.Application.UseCases;

public sealed class ListarComprasProveedorReporteUseCase(IReporteComprasProveedorService reporteComprasProveedorService)
{
    public Task<IReadOnlyCollection<ComprasProveedorReporteDto>> ExecuteAsync(
        ComprasProveedorReporteFiltersDto filters,
        CancellationToken cancellationToken) =>
        reporteComprasProveedorService.GetBySupplierAsync(filters, cancellationToken);
}
