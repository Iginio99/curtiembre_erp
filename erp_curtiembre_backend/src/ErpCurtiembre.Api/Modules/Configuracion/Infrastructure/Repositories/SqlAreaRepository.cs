using Dapper;
using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Repositories;

public sealed class SqlAreaRepository(
    ISqlConnectionFactory connectionFactory,
    ConfiguracionDbContext dbContext) : IAreaRepository
{
    public async Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.area
                WHERE codigo = @Codigo
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { Codigo = codigo, ExcludeId = excludeId }, cancellationToken: cancellationToken));
    }

    public async Task<Area?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                descripcion AS Descripcion,
                activo AS Activo,
                creado_en AS CreadoEn,
                actualizado_en AS ActualizadoEn
            FROM configuracion.area
            WHERE id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Area>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(Area area, CancellationToken cancellationToken)
    {
        var entity = new AreaWriteModel
        {
            Codigo = area.Codigo,
            Nombre = area.Nombre,
            Descripcion = area.Descripcion,
            Activo = area.Activo,
            ActualizadoEn = area.ActualizadoEn
        };

        dbContext.Areas.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(Area area, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Areas.SingleOrDefaultAsync(x => x.Id == area.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Codigo = area.Codigo;
        entity.Nombre = area.Nombre;
        entity.Descripcion = area.Descripcion;
        entity.ActualizadoEn = area.ActualizadoEn;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetActiveAsync(long id, bool activo, DateTime updatedAt, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Areas.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = activo;
        entity.ActualizadoEn = updatedAt;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<Area>> ListAsync(AreaFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                descripcion AS Descripcion,
                activo AS Activo,
                creado_en AS CreadoEn,
                actualizado_en AS ActualizadoEn
            FROM configuracion.area
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
        var items = await connection.QueryAsync<Area>(
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

    public async Task<IReadOnlyCollection<Area>> ListActiveAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                descripcion AS Descripcion,
                activo AS Activo,
                creado_en AS CreadoEn,
                actualizado_en AS ActualizadoEn
            FROM configuracion.area
            WHERE activo = 1
            ORDER BY nombre, codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Area>(new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }
}
