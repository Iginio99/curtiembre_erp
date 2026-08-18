using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlProcesoProductivoLookupRepository(ISqlConnectionFactory connectionFactory) : IProcesoProductivoLookupRepository
{
    private static readonly string[] ExpectedSequenceCodes =
    [
        "REMOJO",
        "PELAMBRE",
        "CURTIDO",
        "RECURTIDO",
        "ACABADO"
    ];

    public async Task<IReadOnlyCollection<ProcesoProductivoLookup>> ListBaseSequenceAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                p.id AS Id,
                p.codigo AS Codigo,
                p.nombre AS Nombre,
                p.orden_secuencia AS OrdenSecuencia,
                p.es_obligatorio AS EsObligatorio,
                p.activo AS Activo
            FROM configuracion.proceso_productivo p
            WHERE p.activo = 1
              AND p.es_obligatorio = 1
              AND p.codigo IN @ExpectedCodes
            ORDER BY
                CASE p.codigo
                    WHEN 'REMOJO' THEN 1
                    WHEN 'PELAMBRE' THEN 2
                    WHEN 'CURTIDO' THEN 3
                    WHEN 'RECURTIDO' THEN 4
                    WHEN 'ACABADO' THEN 5
                    ELSE 999
                END,
                p.orden_secuencia,
                p.id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ProcesoProductivoLookup>(
            new CommandDefinition(
                sql,
                new { ExpectedCodes = ExpectedSequenceCodes },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
