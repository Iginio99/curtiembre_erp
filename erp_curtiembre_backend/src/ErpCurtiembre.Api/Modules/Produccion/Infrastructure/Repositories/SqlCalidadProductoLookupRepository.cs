using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlCalidadProductoLookupRepository(ISqlConnectionFactory connectionFactory) : ICalidadProductoLookupRepository
{
    public async Task<CalidadProductoLookup?> FindActiveByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                c.id AS Id,
                c.codigo AS Codigo,
                c.nombre AS Nombre,
                c.activo AS Activo
            FROM configuracion.calidad_producto c
            WHERE c.id = @Id
              AND c.activo = 1;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<CalidadProductoLookup>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }
}
