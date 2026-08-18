using ErpCurtiembre.Modules.Seguridad.Domain.Entities;

namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface ISesionRepository
{
    Task<long> CreateAsync(SesionUsuario sesion, CancellationToken cancellationToken);

    Task<SesionActiva?> FindActiveByTokenHashAsync(string tokenHash, CancellationToken cancellationToken);

    Task RefreshExpirationAsync(long sesionId, DateTime expiraEn, CancellationToken cancellationToken);

    Task CloseAsync(long sesionId, string motivoCierre, DateTime closedAt, CancellationToken cancellationToken);

    Task CloseAllByUserAsync(long usuarioId, string motivoCierre, DateTime closedAt, CancellationToken cancellationToken);
}
