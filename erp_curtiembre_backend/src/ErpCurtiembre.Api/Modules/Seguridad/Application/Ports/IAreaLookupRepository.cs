namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface IAreaLookupRepository
{
    Task<bool> ExistsActiveAsync(long areaId, CancellationToken cancellationToken);
}
