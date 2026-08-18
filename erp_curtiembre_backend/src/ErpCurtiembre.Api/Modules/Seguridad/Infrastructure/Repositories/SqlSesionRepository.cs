using Dapper;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Repositories;

public sealed class SqlSesionRepository(
    ISqlConnectionFactory connectionFactory,
    SeguridadDbContext dbContext) : ISesionRepository
{
    public async Task<long> CreateAsync(SesionUsuario sesion, CancellationToken cancellationToken)
    {
        var entity = new SesionUsuarioWriteModel
        {
            UsuarioId = sesion.UsuarioId,
            TokenHash = sesion.TokenHash,
            IpOrigen = sesion.IpOrigen,
            UserAgent = sesion.UserAgent,
            InicioEn = sesion.InicioEn,
            ExpiraEn = sesion.ExpiraEn,
            CerradoEn = sesion.CerradoEn,
            MotivoCierre = sesion.MotivoCierre,
            Activa = sesion.Activa
        };

        dbContext.SesionesUsuario.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task<SesionActiva?> FindActiveByTokenHashAsync(string tokenHash, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                s.id AS SesionId,
                u.id AS UsuarioId,
                u.rol_id AS RolId,
                u.usuario AS Usuario,
                u.nombres AS Nombres,
                u.apellidos AS Apellidos,
                r.codigo AS RolCodigo,
                r.nombre AS RolNombre,
                u.activo AS UsuarioActivo,
                r.activo AS RolActivo,
                u.debe_cambiar_password AS DebeCambiarPassword,
                s.expira_en AS ExpiraEn
            FROM seguridad.sesion_usuario s
            INNER JOIN seguridad.usuario u ON u.id = s.usuario_id
            INNER JOIN seguridad.rol r ON r.id = u.rol_id
            WHERE s.token_hash = @TokenHash
              AND s.activa = 1
              AND s.cerrado_en IS NULL;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<SesionActiva>(
            new CommandDefinition(sql, new { TokenHash = tokenHash }, cancellationToken: cancellationToken));
    }

    public async Task RefreshExpirationAsync(long sesionId, DateTime expiraEn, CancellationToken cancellationToken)
    {
        var entity = await dbContext.SesionesUsuario.SingleOrDefaultAsync(x => x.Id == sesionId && x.Activa, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.ExpiraEn = expiraEn;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task CloseAsync(long sesionId, string motivoCierre, DateTime closedAt, CancellationToken cancellationToken)
    {
        var entity = await dbContext.SesionesUsuario.SingleOrDefaultAsync(x => x.Id == sesionId && x.Activa, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activa = false;
        entity.CerradoEn = closedAt;
        entity.MotivoCierre = motivoCierre;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task CloseAllByUserAsync(long usuarioId, string motivoCierre, DateTime closedAt, CancellationToken cancellationToken)
    {
        var entities = await dbContext.SesionesUsuario
            .Where(x => x.UsuarioId == usuarioId && x.Activa)
            .ToListAsync(cancellationToken);

        foreach (var entity in entities)
        {
            entity.Activa = false;
            entity.CerradoEn = closedAt;
            entity.MotivoCierre = motivoCierre;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
