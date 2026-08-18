using ErpCurtiembre.Modules.Configuracion.Domain.Entities;

namespace ErpCurtiembre.Modules.Configuracion.Application.Ports;

public interface IConfiguracionQueryService
{
    Task<IReadOnlyCollection<ParametroSistema>> ListAsync(CancellationToken cancellationToken);

    Task<IReadOnlyDictionary<string, ParametroSistema>> GetByClavesAsync(
        IEnumerable<string> claves,
        CancellationToken cancellationToken);
}
