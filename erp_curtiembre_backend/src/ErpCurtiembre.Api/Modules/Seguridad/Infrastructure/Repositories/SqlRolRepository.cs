using Dapper;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Repositories;

public sealed class SqlRolRepository(ISqlConnectionFactory connectionFactory) : IRolRepository
{
    public async Task<Rol?> FindByIdAsync(long rolId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                descripcion AS Descripcion,
                activo AS Activo,
                creado_en AS CreadoEn
            FROM seguridad.rol
            WHERE id = @RolId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Rol>(
            new CommandDefinition(sql, new { RolId = rolId }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<Rol>> ListActiveAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                descripcion AS Descripcion,
                activo AS Activo,
                creado_en AS CreadoEn
            FROM seguridad.rol
            WHERE activo = 1
            ORDER BY nombre;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Rol>(new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }
}
