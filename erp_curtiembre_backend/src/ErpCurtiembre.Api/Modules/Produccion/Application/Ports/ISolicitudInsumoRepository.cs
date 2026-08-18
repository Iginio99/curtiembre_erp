using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface ISolicitudInsumoRepository
{
    Task<long> CreateAsync(
        SolicitudInsumo solicitud,
        IReadOnlyCollection<SolicitudInsumoDetalle> detalles,
        CancellationToken cancellationToken);

    Task<SolicitudInsumo?> FindByIdAsync(long id, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<SolicitudInsumo>> ListAsync(string? estado, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<SolicitudInsumoDetalle>> ListDetailsAsync(long solicitudId, CancellationToken cancellationToken);

    Task<bool> HasOpenRequestForProcessAsync(long ordenProcesoId, CancellationToken cancellationToken);

    Task<bool> TryStartDeliveryAsync(long id, CancellationToken cancellationToken);

    Task<bool> CompleteDeliveryAsync(long id, CancellationToken cancellationToken);

    Task ReopenDeliveryAsync(long id, CancellationToken cancellationToken);
}
