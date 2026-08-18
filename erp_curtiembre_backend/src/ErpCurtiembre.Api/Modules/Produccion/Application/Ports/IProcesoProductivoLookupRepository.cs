using ErpCurtiembre.Modules.Produccion.Domain.Entities;

namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface IProcesoProductivoLookupRepository
{
    Task<IReadOnlyCollection<ProcesoProductivoLookup>> ListBaseSequenceAsync(CancellationToken cancellationToken);
}
