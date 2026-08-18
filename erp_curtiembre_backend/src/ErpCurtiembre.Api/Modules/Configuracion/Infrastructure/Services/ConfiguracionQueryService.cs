using Dapper;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Services;

public sealed class ConfiguracionQueryService(ISqlConnectionFactory connectionFactory) : IConfiguracionQueryService
{
    public async Task<IReadOnlyCollection<ParametroSistema>> ListAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                clave AS Clave,
                valor AS Valor,
                descripcion AS Descripcion,
                tipo_dato AS TipoDato,
                editable AS Editable,
                actualizado_en AS ActualizadoEn
            FROM configuracion.parametro_sistema
            ORDER BY clave;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ParametroSistema>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyDictionary<string, ParametroSistema>> GetByClavesAsync(
        IEnumerable<string> claves,
        CancellationToken cancellationToken)
    {
        var normalizedClaves = claves
            .Where(clave => !string.IsNullOrWhiteSpace(clave))
            .Select(clave => clave.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        if (normalizedClaves.Length == 0)
        {
            return new Dictionary<string, ParametroSistema>(StringComparer.OrdinalIgnoreCase);
        }

        const string sql = """
            SELECT
                id AS Id,
                clave AS Clave,
                valor AS Valor,
                descripcion AS Descripcion,
                tipo_dato AS TipoDato,
                editable AS Editable,
                actualizado_en AS ActualizadoEn
            FROM configuracion.parametro_sistema
            WHERE clave IN @Claves;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ParametroSistema>(
            new CommandDefinition(sql, new { Claves = normalizedClaves }, cancellationToken: cancellationToken));

        return items.ToDictionary(item => item.Clave, StringComparer.OrdinalIgnoreCase);
    }
}
