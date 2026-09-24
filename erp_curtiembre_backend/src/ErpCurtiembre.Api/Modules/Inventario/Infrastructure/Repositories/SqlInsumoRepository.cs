using Dapper;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;

public sealed class SqlInsumoRepository(
    ISqlConnectionFactory connectionFactory,
    InventarioDbContext dbContext) : IInsumoRepository
{
    public async Task<string> GenerateNextCodeAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT ISNULL(MAX(TRY_CONVERT(int, SUBSTRING(codigo, 5, 20))), 0) + 1
            FROM inventario.insumo
            WHERE codigo LIKE 'INS-%';
            """;
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var next = await connection.ExecuteScalarAsync<int>(new CommandDefinition(sql, cancellationToken: cancellationToken));
        return $"INS-{next:D3}";
    }

    public async Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT CASE WHEN EXISTS (
                SELECT 1
                FROM inventario.insumo
                WHERE codigo = @Codigo
                  AND (@ExcludeId IS NULL OR id <> @ExcludeId)
            ) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<bool>(
            new CommandDefinition(sql, new { Codigo = codigo, ExcludeId = excludeId }, cancellationToken: cancellationToken));
    }

    public async Task<Insumo?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                i.id AS Id,
                CASE
                    WHEN i.codigo LIKE 'INS-%' AND TRY_CONVERT(int, SUBSTRING(i.codigo, 5, 20)) IS NOT NULL
                    THEN 'INS-' + RIGHT('000' + CONVERT(varchar(10), TRY_CONVERT(int, SUBSTRING(i.codigo, 5, 20))), 3)
                    ELSE i.codigo
                END AS Codigo,
                i.nombre AS Nombre,
                i.tipo_bien AS TipoBien,
                i.presentacion AS Presentacion,
                i.unidad_medida_id AS UnidadMedidaId,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                i.stock_minimo AS StockMinimo,
                ISNULL(s.costo_promedio_actual, i.costo_promedio_actual) AS CostoPromedioActual,
                ISNULL(s.cantidad_actual, 0) AS StockActual,
                i.requiere_lote AS RequiereLote,
                i.activo AS Activo,
                i.creado_en AS CreadoEn,
                i.creado_por_usuario_id AS CreadoPorUsuarioId,
                i.actualizado_en AS ActualizadoEn,
                i.actualizado_por_usuario_id AS ActualizadoPorUsuarioId
            FROM inventario.insumo i
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            LEFT JOIN inventario.stock_insumo s ON s.insumo_id = i.id
            WHERE i.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Insumo>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(Insumo insumo, long? actorId, CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var entity = new InsumoWriteModel
        {
            Codigo = insumo.Codigo,
            Nombre = insumo.Nombre,
            TipoBien = insumo.TipoBien,
            Presentacion = insumo.Presentacion,
            UnidadMedidaId = insumo.UnidadMedidaId,
            StockMinimo = insumo.StockMinimo,
            CostoPromedioActual = 0,
            RequiereLote = insumo.RequiereLote,
            Activo = insumo.Activo,
            CreadoPorUsuarioId = actorId
        };

        dbContext.Insumos.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        dbContext.StocksInsumo.Add(new StockInsumoWriteModel
        {
            InsumoId = entity.Id,
            CantidadActual = 0,
            CostoPromedioActual = 0
        });

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(Insumo insumo, long? actorId, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Insumos.SingleOrDefaultAsync(x => x.Id == insumo.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Nombre = insumo.Nombre;
        entity.TipoBien = insumo.TipoBien;
        entity.Presentacion = insumo.Presentacion;
        entity.UnidadMedidaId = insumo.UnidadMedidaId;
        entity.StockMinimo = insumo.StockMinimo;
        entity.RequiereLote = insumo.RequiereLote;
        entity.ActualizadoEn = insumo.ActualizadoEn;
        entity.ActualizadoPorUsuarioId = actorId;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetActiveAsync(
        long id,
        bool activo,
        DateTime updatedAt,
        long? actorId,
        CancellationToken cancellationToken)
    {
        var entity = await dbContext.Insumos.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Activo = activo;
        entity.ActualizadoEn = updatedAt;
        entity.ActualizadoPorUsuarioId = actorId;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<Insumo>> ListAsync(InsumoFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                i.id AS Id,
                CASE
                    WHEN i.codigo LIKE 'INS-%' AND TRY_CONVERT(int, SUBSTRING(i.codigo, 5, 20)) IS NOT NULL
                    THEN 'INS-' + RIGHT('000' + CONVERT(varchar(10), TRY_CONVERT(int, SUBSTRING(i.codigo, 5, 20))), 3)
                    ELSE i.codigo
                END AS Codigo,
                i.nombre AS Nombre,
                i.tipo_bien AS TipoBien,
                i.presentacion AS Presentacion,
                i.unidad_medida_id AS UnidadMedidaId,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                i.stock_minimo AS StockMinimo,
                ISNULL(s.costo_promedio_actual, i.costo_promedio_actual) AS CostoPromedioActual,
                ISNULL(s.cantidad_actual, 0) AS StockActual,
                i.requiere_lote AS RequiereLote,
                i.activo AS Activo,
                i.creado_en AS CreadoEn,
                i.creado_por_usuario_id AS CreadoPorUsuarioId,
                i.actualizado_en AS ActualizadoEn,
                i.actualizado_por_usuario_id AS ActualizadoPorUsuarioId
            FROM inventario.insumo i
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            LEFT JOIN inventario.stock_insumo s ON s.insumo_id = i.id
            WHERE (
                    @Texto IS NULL OR
                    i.codigo LIKE @TextoLike OR
                    i.nombre LIKE @TextoLike OR
                    i.presentacion LIKE @TextoLike
                )
              AND (@TipoBien IS NULL OR i.tipo_bien = @TipoBien)
              AND (@UnidadMedidaId IS NULL OR i.unidad_medida_id = @UnidadMedidaId)
              AND (@Activo IS NULL OR i.activo = @Activo)
              AND (
                    @StockBajo IS NULL OR
                    (@StockBajo = 1 AND ISNULL(s.cantidad_actual, 0) <= i.stock_minimo) OR
                    (@StockBajo = 0 AND ISNULL(s.cantidad_actual, 0) > i.stock_minimo)
                )
            ORDER BY TRY_CONVERT(int, SUBSTRING(i.codigo, 5, 20)), i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Insumo>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.TipoBien,
                    filters.UnidadMedidaId,
                    filters.Activo,
                    filters.StockBajo
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<Insumo>> ListActiveAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                i.id AS Id,
                CASE
                    WHEN i.codigo LIKE 'INS-%' AND TRY_CONVERT(int, SUBSTRING(i.codigo, 5, 20)) IS NOT NULL
                    THEN 'INS-' + RIGHT('000' + CONVERT(varchar(10), TRY_CONVERT(int, SUBSTRING(i.codigo, 5, 20))), 3)
                    ELSE i.codigo
                END AS Codigo,
                i.nombre AS Nombre,
                i.tipo_bien AS TipoBien,
                i.presentacion AS Presentacion,
                i.unidad_medida_id AS UnidadMedidaId,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                i.stock_minimo AS StockMinimo,
                ISNULL(s.costo_promedio_actual, i.costo_promedio_actual) AS CostoPromedioActual,
                ISNULL(s.cantidad_actual, 0) AS StockActual,
                i.requiere_lote AS RequiereLote,
                i.activo AS Activo,
                i.creado_en AS CreadoEn,
                i.creado_por_usuario_id AS CreadoPorUsuarioId,
                i.actualizado_en AS ActualizadoEn,
                i.actualizado_por_usuario_id AS ActualizadoPorUsuarioId
            FROM inventario.insumo i
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            LEFT JOIN inventario.stock_insumo s ON s.insumo_id = i.id
            WHERE i.activo = 1
            ORDER BY TRY_CONVERT(int, SUBSTRING(i.codigo, 5, 20)), i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Insumo>(new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }
}
