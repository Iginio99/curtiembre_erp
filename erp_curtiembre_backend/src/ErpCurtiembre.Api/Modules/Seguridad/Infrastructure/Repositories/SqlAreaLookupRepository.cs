using Dapper;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Repositories;

public sealed class SqlAreaLookupRepository(ISqlConnectionFactory connectionFactory) : IAreaLookupRepository
{
    public async Task<bool> ExistsActiveAsync(long areaId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.area
                WHERE id = @AreaId
                  AND activo = 1
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { AreaId = areaId }, cancellationToken: cancellationToken));
    }
}
