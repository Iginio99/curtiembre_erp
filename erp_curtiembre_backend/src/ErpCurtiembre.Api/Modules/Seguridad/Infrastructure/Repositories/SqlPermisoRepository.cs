using Dapper;
using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Repositories;

public sealed class SqlPermisoRepository(ISqlConnectionFactory connectionFactory) : IPermisoRepository
{
    public async Task<IReadOnlyCollection<Permiso>> ListAsync(PermissionFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                modulo AS Modulo,
                accion AS Accion,
                descripcion AS Descripcion,
                activo AS Activo
            FROM seguridad.permiso
            WHERE (@Modulo IS NULL OR modulo = @Modulo)
              AND (@Accion IS NULL OR accion = @Accion)
              AND (@Activo IS NULL OR activo = @Activo)
            ORDER BY modulo, codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Permiso>(
            new CommandDefinition(sql, filters, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<Permiso>> GetPermissionsByUserAsync(long usuarioId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                p.id AS Id,
                p.codigo AS Codigo,
                p.modulo AS Modulo,
                p.accion AS Accion,
                p.descripcion AS Descripcion,
                p.activo AS Activo
            FROM seguridad.usuario u
            INNER JOIN seguridad.rol r ON r.id = u.rol_id
            INNER JOIN seguridad.rol_permiso rp ON rp.rol_id = r.id
            INNER JOIN seguridad.permiso p ON p.id = rp.permiso_id
            WHERE u.id = @UsuarioId
              AND u.activo = 1
              AND r.activo = 1
              AND p.activo = 1
            ORDER BY p.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Permiso>(
            new CommandDefinition(sql, new { UsuarioId = usuarioId }, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<bool> UserHasPermissionAsync(long usuarioId, string permissionCode, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM seguridad.usuario u
                INNER JOIN seguridad.rol r ON r.id = u.rol_id
                INNER JOIN seguridad.rol_permiso rp ON rp.rol_id = r.id
                INNER JOIN seguridad.permiso p ON p.id = rp.permiso_id
                WHERE u.id = @UsuarioId
                  AND u.activo = 1
                  AND r.activo = 1
                  AND p.activo = 1
                  AND p.codigo = @PermissionCode
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(
                sql,
                new { UsuarioId = usuarioId, PermissionCode = permissionCode },
                cancellationToken: cancellationToken));
    }
}
