using Dapper;
using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Repositories;

public sealed class SqlTipoPielRepository(
    ISqlConnectionFactory connectionFactory,
    ConfiguracionDbContext dbContext) : ITipoPielRepository
{
    public async Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.tipo_piel
                WHERE codigo = @Codigo
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { Codigo = codigo, ExcludeId = excludeId }, cancellationToken: cancellationToken));
    }

    public async Task<TipoPiel?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                descripcion AS Descripcion,
                activo AS Activo,
                creado_en AS CreadoEn
            FROM configuracion.tipo_piel
            WHERE id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<TipoPiel>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(TipoPiel tipoPiel, CancellationToken cancellationToken)
    {
        var entity = new TipoPielWriteModel
        {
            Codigo = tipoPiel.Codigo,
            Nombre = tipoPiel.Nombre,
            Descripcion = tipoPiel.Descripcion,
            Activo = tipoPiel.Activo
        };

        dbContext.TiposPiel.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(TipoPiel tipoPiel, CancellationToken cancellationToken)
    {
        var entity = await dbContext.TiposPiel.SingleOrDefaultAsync(x => x.Id == tipoPiel.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Codigo = tipoPiel.Codigo;
        entity.Nombre = tipoPiel.Nombre;
        entity.Descripcion = tipoPiel.Descripcion;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetActiveAsync(long id, bool activo, CancellationToken cancellationToken)
    {
        var entity = await dbContext.TiposPiel.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = activo;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<TipoPiel>> ListAsync(TipoPielFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                descripcion AS Descripcion,
                activo AS Activo,
                creado_en AS CreadoEn
            FROM configuracion.tipo_piel
            WHERE (
                    @Texto IS NULL OR
                    codigo LIKE @TextoLike OR
                    nombre LIKE @TextoLike OR
                    descripcion LIKE @TextoLike
                )
              AND (@Activo IS NULL OR activo = @Activo)
            ORDER BY nombre, codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<TipoPiel>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.Activo
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<TipoPiel>> ListActiveAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                descripcion AS Descripcion,
                activo AS Activo,
                creado_en AS CreadoEn
            FROM configuracion.tipo_piel
            WHERE activo = 1
            ORDER BY nombre, codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<TipoPiel>(new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }
}
