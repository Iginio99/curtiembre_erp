using ErpCurtiembre.Modules.Seguridad.Domain.Entities;

namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface ILoginAttemptRepository
{
    Task RegisterAsync(IntentoLogin intentoLogin, CancellationToken cancellationToken);
}
