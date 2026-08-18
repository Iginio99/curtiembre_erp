namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public interface IUnidadMedidaLookupRepository
{
    Task<bool> ExistsActiveAsync(long unidadMedidaId, CancellationToken cancellationToken);
}
