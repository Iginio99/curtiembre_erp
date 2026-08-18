using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlUsuarioLookupRepository(ISqlConnectionFactory connectionFactory) : IUsuarioLookupRepository
{
    public async Task<UsuarioLookup?> FindActiveByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                u.id AS Id,
                u.usuario AS UserName,
                LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) AS NombreCompleto
            FROM seguridad.usuario u
            WHERE u.id = @Id
              AND u.activo = 1;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<UsuarioLookup>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }
}
