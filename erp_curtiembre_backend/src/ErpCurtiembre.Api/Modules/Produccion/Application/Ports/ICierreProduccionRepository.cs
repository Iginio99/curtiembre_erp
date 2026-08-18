using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface ICierreProduccionRepository
{
    Task<long> RegisterMermaAsync(MermaProceso merma, CancellationToken cancellationToken);

    Task<MermaProceso?> FindMermaByIdAsync(long id, CancellationToken cancellationToken);

    Task<long> RegisterControlCalidadAsync(ControlCalidad quality, CancellationToken cancellationToken);

    Task<ControlCalidad?> FindControlCalidadByIdAsync(long id, CancellationToken cancellationToken);

    Task<ControlCalidad?> FindLatestControlCalidadAsync(long orderId, CancellationToken cancellationToken);

    Task<ProductoTerminado?> FindProductoTerminadoByOrderIdAsync(long orderId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<ProductoTerminado>> ListProductosTerminadosAsync(CancellationToken cancellationToken);

    Task<long> FinalizeOrderAsync(
        FinalizacionProduccion finalizacion,
        CancellationToken cancellationToken);
}
