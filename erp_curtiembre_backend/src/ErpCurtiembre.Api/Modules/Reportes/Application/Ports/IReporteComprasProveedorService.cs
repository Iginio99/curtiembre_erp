using ErpCurtiembre.Modules.Reportes.Application.DTOs;

namespace ErpCurtiembre.Modules.Reportes.Application.Ports;

public interface IReporteComprasProveedorService
{
    Task<IReadOnlyCollection<ComprasProveedorReporteDto>> GetBySupplierAsync(
        ComprasProveedorReporteFiltersDto filters,
        CancellationToken cancellationToken);
}
