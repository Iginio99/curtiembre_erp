using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Repositories;

public sealed class SqlLoginAttemptRepository(SeguridadDbContext dbContext) : ILoginAttemptRepository
{
    public async Task RegisterAsync(IntentoLogin intentoLogin, CancellationToken cancellationToken)
    {
        var entity = new IntentoLoginWriteModel
        {
            UsuarioLogin = intentoLogin.UsuarioLogin,
            UsuarioId = intentoLogin.UsuarioId,
            FueExitoso = intentoLogin.FueExitoso,
            IpOrigen = intentoLogin.IpOrigen,
            Mensaje = intentoLogin.Mensaje
        };

        dbContext.IntentosLogin.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
