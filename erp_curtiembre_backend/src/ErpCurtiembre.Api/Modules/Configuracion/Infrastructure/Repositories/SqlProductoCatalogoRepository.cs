using Dapper;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Repositories;

public sealed class SqlProductoCatalogoRepository(ISqlConnectionFactory connectionFactory, ConfiguracionDbContext dbContext) : IProductoCatalogoRepository
{
    public async Task<IReadOnlyCollection<ProductoCatalogo>> ListAsync(bool? activo, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT id AS Id, codigo AS Codigo, tipo AS Tipo, nombre AS Nombre, color AS Color, activo AS Activo, creado_en AS CreadoEn
            FROM configuracion.producto
            WHERE (@Activo IS NULL OR activo = @Activo)
            ORDER BY tipo, nombre, color, codigo;
            """;
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return (await connection.QueryAsync<ProductoCatalogo>(new CommandDefinition(sql, new { Activo = activo }, cancellationToken: cancellationToken))).ToArray();
    }

    public async Task<ProductoCatalogo?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT id AS Id, codigo AS Codigo, tipo AS Tipo, nombre AS Nombre, color AS Color, activo AS Activo, creado_en AS CreadoEn
            FROM configuracion.producto WHERE id=@Id;
            """;
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ProductoCatalogo>(new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<bool> ExistsCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(new CommandDefinition("SELECT CAST(CASE WHEN EXISTS (SELECT 1 FROM configuracion.producto WHERE codigo=@Codigo AND (@ExcludeId IS NULL OR id<>@ExcludeId)) THEN 1 ELSE 0 END AS bit)", new { Codigo = codigo, ExcludeId = excludeId }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(ProductoCatalogo producto, CancellationToken cancellationToken)
    {
        var entity = new ProductoCatalogoWriteModel { Codigo = producto.Codigo, Tipo = producto.Tipo, Nombre = producto.Nombre, Color = producto.Color, Activo = producto.Activo };
        dbContext.Productos.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(ProductoCatalogo producto, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Productos.SingleOrDefaultAsync(x => x.Id == producto.Id, cancellationToken);
        if (entity is null) return;
        entity.Codigo = producto.Codigo; entity.Tipo = producto.Tipo; entity.Nombre = producto.Nombre; entity.Color = producto.Color;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetActiveAsync(long id, bool activo, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Productos.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null) return;
        entity.Activo = activo;
        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
