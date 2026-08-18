using Dapper;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;

public sealed class SqlStockRepository(ISqlConnectionFactory connectionFactory) : IStockRepository
{
    public async Task<IReadOnlyCollection<StockActual>> ListAsync(StockFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                i.id AS InsumoId,
                i.codigo AS Codigo,
                i.nombre AS Nombre,
                i.tipo_bien AS TipoBien,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                i.stock_minimo AS StockMinimo,
                ISNULL(s.cantidad_actual, 0) AS CantidadActual,
                ISNULL(s.costo_promedio_actual, i.costo_promedio_actual) AS CostoPromedioActual,
                i.activo AS Activo,
                CASE WHEN ISNULL(s.cantidad_actual, 0) <= i.stock_minimo THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS StockBajo,
                ISNULL(s.actualizado_en, i.creado_en) AS ActualizadoEn
            FROM inventario.insumo i
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            LEFT JOIN inventario.stock_insumo s ON s.insumo_id = i.id
            WHERE (
                    @Texto IS NULL OR
                    i.codigo LIKE @TextoLike OR
                    i.nombre LIKE @TextoLike OR
                    i.tipo_bien LIKE @TextoLike
                )
              AND (@TipoBien IS NULL OR i.tipo_bien = @TipoBien)
              AND (@Activo IS NULL OR i.activo = @Activo)
              AND (
                    @StockBajo IS NULL OR
                    (@StockBajo = 1 AND ISNULL(s.cantidad_actual, 0) <= i.stock_minimo) OR
                    (@StockBajo = 0 AND ISNULL(s.cantidad_actual, 0) > i.stock_minimo)
                )
            ORDER BY i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<StockActual>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.TipoBien,
                    filters.StockBajo,
                    filters.Activo
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<StockActual?> GetByInsumoIdAsync(long insumoId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                i.id AS InsumoId,
                i.codigo AS Codigo,
                i.nombre AS Nombre,
                i.tipo_bien AS TipoBien,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                i.stock_minimo AS StockMinimo,
                ISNULL(s.cantidad_actual, 0) AS CantidadActual,
                ISNULL(s.costo_promedio_actual, i.costo_promedio_actual) AS CostoPromedioActual,
                i.activo AS Activo,
                CASE WHEN ISNULL(s.cantidad_actual, 0) <= i.stock_minimo THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS StockBajo,
                ISNULL(s.actualizado_en, i.creado_en) AS ActualizadoEn
            FROM inventario.insumo i
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            LEFT JOIN inventario.stock_insumo s ON s.insumo_id = i.id
            WHERE i.id = @InsumoId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<StockActual>(
            new CommandDefinition(sql, new { InsumoId = insumoId }, cancellationToken: cancellationToken));
    }
}
