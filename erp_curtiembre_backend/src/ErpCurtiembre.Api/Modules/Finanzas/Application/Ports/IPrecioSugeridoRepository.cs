using ErpCurtiembre.Modules.Finanzas.Domain.Entities;

namespace ErpCurtiembre.Modules.Finanzas.Application.Ports;

public interface IPrecioSugeridoRepository
{
    Task<PrecioSugerido?> FindByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken);

    Task UpsertAsync(PrecioSugerido precioSugerido, CancellationToken cancellationToken);
}
