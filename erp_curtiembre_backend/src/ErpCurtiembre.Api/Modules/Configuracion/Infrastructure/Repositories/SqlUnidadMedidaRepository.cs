using Dapper;
using ErpCurtiembre.Modules.Configuracion.Application.DTOs;
using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Domain.Entities;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Repositories;

public sealed class SqlUnidadMedidaRepository(
    ISqlConnectionFactory connectionFactory,
    ConfiguracionDbContext dbContext) : IUnidadMedidaRepository
{
    public async Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM configuracion.unidad_medida
                WHERE codigo = @Codigo
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { Codigo = codigo, ExcludeId = excludeId }, cancellationToken: cancellationToken));
    }

    public async Task<UnidadMedida?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                permite_decimales AS PermiteDecimales,
                activo AS Activo,
                creado_en AS CreadoEn
            FROM configuracion.unidad_medida
            WHERE id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<UnidadMedida>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(UnidadMedida unidadMedida, CancellationToken cancellationToken)
    {
        var entity = new UnidadMedidaWriteModel
        {
            Codigo = unidadMedida.Codigo,
            Nombre = unidadMedida.Nombre,
            PermiteDecimales = unidadMedida.PermiteDecimales,
            Activo = unidadMedida.Activo
        };

        dbContext.UnidadesMedida.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(UnidadMedida unidadMedida, CancellationToken cancellationToken)
    {
        var entity = await dbContext.UnidadesMedida.SingleOrDefaultAsync(x => x.Id == unidadMedida.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Codigo = unidadMedida.Codigo;
        entity.Nombre = unidadMedida.Nombre;
        entity.PermiteDecimales = unidadMedida.PermiteDecimales;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetActiveAsync(long id, bool activo, CancellationToken cancellationToken)
    {
        var entity = await dbContext.UnidadesMedida.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = activo;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<UnidadMedida>> ListAsync(UnidadMedidaFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                permite_decimales AS PermiteDecimales,
                activo AS Activo,
                creado_en AS CreadoEn
            FROM configuracion.unidad_medida
            WHERE (
                    @Texto IS NULL OR
                    codigo LIKE @TextoLike OR
                    nombre LIKE @TextoLike
                )
              AND (@Activo IS NULL OR activo = @Activo)
              AND (@PermiteDecimales IS NULL OR permite_decimales = @PermiteDecimales)
            ORDER BY nombre, codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<UnidadMedida>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.Activo,
                    filters.PermiteDecimales
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<UnidadMedida>> ListActiveAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                codigo AS Codigo,
                nombre AS Nombre,
                permite_decimales AS PermiteDecimales,
                activo AS Activo,
                creado_en AS CreadoEn
            FROM configuracion.unidad_medida
            WHERE activo = 1
            ORDER BY nombre, codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<UnidadMedida>(new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }
}
