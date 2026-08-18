using System.Data;

namespace ErpCurtiembre.Shared.Persistence;

public interface ISqlConnectionFactory
{
    Task<IDbConnection> CreateOpenConnectionAsync(CancellationToken cancellationToken);
}
