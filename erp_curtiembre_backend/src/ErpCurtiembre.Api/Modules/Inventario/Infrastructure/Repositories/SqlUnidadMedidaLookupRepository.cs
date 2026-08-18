using Dapper;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;

public sealed class SqlUnidadMedidaLookupRepository(ISqlConnectionFactory connectionFactory)
    : IUnidadMedidaLookupRepository
{
    public async Task<bool> ExistsActiveAsync(long unidadMedidaId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.unidad_medida
                WHERE id = @UnidadMedidaId
                  AND activo = 1
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { UnidadMedidaId = unidadMedidaId }, cancellationToken: cancellationToken));
    }
}
