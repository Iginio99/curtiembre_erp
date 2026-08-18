using Dapper;
using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Repositories;

public sealed class SqlUsuarioRepository(
    ISqlConnectionFactory connectionFactory,
    SeguridadDbContext dbContext) : IUsuarioRepository
{
    public async Task<bool> HasAnyUserAsync(CancellationToken cancellationToken)
    {
        const string sql = "SELECT CASE WHEN EXISTS (SELECT 1 FROM seguridad.usuario) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;";
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(new CommandDefinition(sql, cancellationToken: cancellationToken));
    }

    public async Task<Usuario?> FindByUserNameAsync(string userName, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                u.id AS Id,
                u.rol_id AS RolId,
                u.area_id AS AreaId,
                u.nombres AS Nombres,
                u.apellidos AS Apellidos,
                u.dni AS Dni,
                u.usuario AS UserName,
                u.password_hash AS PasswordHash,
                u.debe_cambiar_password AS DebeCambiarPassword,
                u.intentos_fallidos AS IntentosFallidos,
                u.bloqueado_hasta AS BloqueadoHasta,
                u.ultimo_login_en AS UltimoLoginEn,
                u.activo AS Activo,
                u.creado_en AS CreadoEn,
                u.creado_por_usuario_id AS CreadoPorUsuarioId,
                u.actualizado_en AS ActualizadoEn,
                u.actualizado_por_usuario_id AS ActualizadoPorUsuarioId,
                r.codigo AS RolCodigo,
                r.nombre AS RolNombre,
                a.nombre AS AreaNombre
            FROM seguridad.usuario u
            INNER JOIN seguridad.rol r ON r.id = u.rol_id
            LEFT JOIN configuracion.area a ON a.id = u.area_id
            WHERE u.usuario = @UserName;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Usuario>(
            new CommandDefinition(sql, new { UserName = userName }, cancellationToken: cancellationToken));
    }

    public async Task<Usuario?> FindByIdAsync(long usuarioId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                u.id AS Id,
                u.rol_id AS RolId,
                u.area_id AS AreaId,
                u.nombres AS Nombres,
                u.apellidos AS Apellidos,
                u.dni AS Dni,
                u.usuario AS UserName,
                u.password_hash AS PasswordHash,
                u.debe_cambiar_password AS DebeCambiarPassword,
                u.intentos_fallidos AS IntentosFallidos,
                u.bloqueado_hasta AS BloqueadoHasta,
                u.ultimo_login_en AS UltimoLoginEn,
                u.activo AS Activo,
                u.creado_en AS CreadoEn,
                u.creado_por_usuario_id AS CreadoPorUsuarioId,
                u.actualizado_en AS ActualizadoEn,
                u.actualizado_por_usuario_id AS ActualizadoPorUsuarioId,
                r.codigo AS RolCodigo,
                r.nombre AS RolNombre,
                a.nombre AS AreaNombre
            FROM seguridad.usuario u
            INNER JOIN seguridad.rol r ON r.id = u.rol_id
            LEFT JOIN configuracion.area a ON a.id = u.area_id
            WHERE u.id = @UsuarioId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Usuario>(
            new CommandDefinition(sql, new { UsuarioId = usuarioId }, cancellationToken: cancellationToken));
    }

    public async Task<bool> ExistsByUserNameAsync(string userName, long? excludeUserId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM seguridad.usuario
                WHERE usuario = @UserName
                  AND (@ExcludeUserId IS NULL OR id <> @ExcludeUserId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { UserName = userName, ExcludeUserId = excludeUserId }, cancellationToken: cancellationToken));
    }

    public async Task<bool> ExistsByDniAsync(string dni, long? excludeUserId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM seguridad.usuario
                WHERE dni = @Dni
                  AND (@ExcludeUserId IS NULL OR id <> @ExcludeUserId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { Dni = dni, ExcludeUserId = excludeUserId }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(Usuario usuario, CancellationToken cancellationToken)
    {
        var entity = new UsuarioWriteModel
        {
            RolId = usuario.RolId,
            AreaId = usuario.AreaId,
            Nombres = usuario.Nombres,
            Apellidos = usuario.Apellidos,
            Dni = usuario.Dni,
            Usuario = usuario.UserName,
            PasswordHash = usuario.PasswordHash,
            DebeCambiarPassword = usuario.DebeCambiarPassword,
            IntentosFallidos = usuario.IntentosFallidos,
            BloqueadoHasta = usuario.BloqueadoHasta,
            UltimoLoginEn = usuario.UltimoLoginEn,
            Activo = usuario.Activo,
            CreadoPorUsuarioId = usuario.CreadoPorUsuarioId,
            ActualizadoEn = usuario.ActualizadoEn,
            ActualizadoPorUsuarioId = usuario.ActualizadoPorUsuarioId
        };

        dbContext.Usuarios.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(Usuario usuario, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Usuarios.SingleOrDefaultAsync(x => x.Id == usuario.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.RolId = usuario.RolId;
        entity.AreaId = usuario.AreaId;
        entity.Nombres = usuario.Nombres;
        entity.Apellidos = usuario.Apellidos;
        entity.Dni = usuario.Dni;
        entity.Usuario = usuario.UserName;
        entity.ActualizadoEn = usuario.ActualizadoEn;
        entity.ActualizadoPorUsuarioId = usuario.ActualizadoPorUsuarioId;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdatePasswordAsync(long usuarioId, string passwordHash, bool debeCambiarPassword, long? actorId, DateTime updatedAt, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Usuarios.SingleOrDefaultAsync(x => x.Id == usuarioId, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.PasswordHash = passwordHash;
        entity.DebeCambiarPassword = debeCambiarPassword;
        entity.IntentosFallidos = 0;
        entity.BloqueadoHasta = null;
        entity.ActualizadoEn = updatedAt;
        entity.ActualizadoPorUsuarioId = actorId;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<int> IncrementFailedAttemptsAsync(long usuarioId, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Usuarios.SingleOrDefaultAsync(x => x.Id == usuarioId, cancellationToken);
        if (entity is null)
        {
            return 0;
        }

        entity.IntentosFallidos += 1;
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.IntentosFallidos;
    }

    public async Task ResetFailedAttemptsAsync(long usuarioId, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Usuarios.SingleOrDefaultAsync(x => x.Id == usuarioId, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.IntentosFallidos = 0;
        entity.BloqueadoHasta = null;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task BlockUntilAsync(long usuarioId, DateTime blockedUntil, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Usuarios.SingleOrDefaultAsync(x => x.Id == usuarioId, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.BloqueadoHasta = blockedUntil;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateLoginSuccessAsync(long usuarioId, DateTime loggedAt, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Usuarios.SingleOrDefaultAsync(x => x.Id == usuarioId, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.IntentosFallidos = 0;
        entity.BloqueadoHasta = null;
        entity.UltimoLoginEn = loggedAt;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task DeactivateAsync(long usuarioId, long actorId, DateTime updatedAt, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Usuarios.SingleOrDefaultAsync(x => x.Id == usuarioId, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = false;
        entity.ActualizadoEn = updatedAt;
        entity.ActualizadoPorUsuarioId = actorId;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task ReactivateAsync(long usuarioId, long actorId, DateTime updatedAt, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Usuarios.SingleOrDefaultAsync(x => x.Id == usuarioId, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = true;
        entity.ActualizadoEn = updatedAt;
        entity.ActualizadoPorUsuarioId = actorId;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<Usuario>> ListAsync(UserFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                u.id AS Id,
                u.rol_id AS RolId,
                u.area_id AS AreaId,
                u.nombres AS Nombres,
                u.apellidos AS Apellidos,
                u.dni AS Dni,
                u.usuario AS UserName,
                u.password_hash AS PasswordHash,
                u.debe_cambiar_password AS DebeCambiarPassword,
                u.intentos_fallidos AS IntentosFallidos,
                u.bloqueado_hasta AS BloqueadoHasta,
                u.ultimo_login_en AS UltimoLoginEn,
                u.activo AS Activo,
                u.creado_en AS CreadoEn,
                u.creado_por_usuario_id AS CreadoPorUsuarioId,
                u.actualizado_en AS ActualizadoEn,
                u.actualizado_por_usuario_id AS ActualizadoPorUsuarioId,
                r.codigo AS RolCodigo,
                r.nombre AS RolNombre,
                a.nombre AS AreaNombre
            FROM seguridad.usuario u
            INNER JOIN seguridad.rol r ON r.id = u.rol_id
            LEFT JOIN configuracion.area a ON a.id = u.area_id
            WHERE (
                    @Texto IS NULL OR
                    u.usuario LIKE @TextoLike OR
                    u.nombres LIKE @TextoLike OR
                    u.apellidos LIKE @TextoLike OR
                    u.dni LIKE @TextoLike
                )
              AND (@RolId IS NULL OR u.rol_id = @RolId)
              AND (@AreaId IS NULL OR u.area_id = @AreaId)
              AND (@Activo IS NULL OR u.activo = @Activo)
            ORDER BY u.id
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;

        var normalizedPage = filters.Page <= 0 ? 1 : filters.Page;
        var normalizedPageSize = filters.PageSize <= 0 ? 20 : filters.PageSize;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Usuario>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.RolId,
                    filters.AreaId,
                    filters.Activo,
                    Offset = (normalizedPage - 1) * normalizedPageSize,
                    PageSize = normalizedPageSize
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
