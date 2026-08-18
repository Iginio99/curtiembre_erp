using System.Data;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Options;

namespace ErpCurtiembre.Shared.Persistence;

public sealed class SqlConnectionFactory(IOptions<DatabaseOptions> databaseOptions) : ISqlConnectionFactory
{
    private readonly DatabaseOptions _databaseOptions = databaseOptions.Value;

    public async Task<IDbConnection> CreateOpenConnectionAsync(CancellationToken cancellationToken)
    {
        var connection = new SqlConnection(_databaseOptions.DefaultConnection);
        await connection.OpenAsync(cancellationToken);
        return connection;
    }
}
