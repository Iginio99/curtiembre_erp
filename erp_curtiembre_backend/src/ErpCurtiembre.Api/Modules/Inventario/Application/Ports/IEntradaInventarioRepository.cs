using ErpCurtiembre.Modules.Inventario.Domain.Entities;

namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IEntradaInventarioRepository
{
    Task<long> RegisterStockInitialAsync(
        StockInitialRegistration registration,
        CancellationToken cancellationToken);

    Task<long> RegisterFromPurchaseAsync(
        PurchaseEntryRegistration registration,
        CancellationToken cancellationToken);

    Task<EntradaInventario?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<EntradaInventarioDetalle>> ListDetailsAsync(long entradaId, CancellationToken cancellationToken);
}
