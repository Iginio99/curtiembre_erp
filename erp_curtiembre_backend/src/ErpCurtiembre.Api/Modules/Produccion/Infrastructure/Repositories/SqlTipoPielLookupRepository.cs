using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlTipoPielLookupRepository(ISqlConnectionFactory connectionFactory) : ITipoPielLookupRepository
{
    public async Task<TipoPielLookup?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                tp.id AS Id,
                tp.codigo AS Codigo,
                tp.nombre AS Nombre,
                tp.activo AS Activo
            FROM configuracion.tipo_piel tp
            WHERE tp.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<TipoPielLookup>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }
}
