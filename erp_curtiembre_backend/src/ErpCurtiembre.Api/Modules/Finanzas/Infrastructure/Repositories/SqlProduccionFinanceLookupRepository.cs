using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlProduccionFinanceLookupRepository(ISqlConnectionFactory connectionFactory)
    : IProduccionFinanceLookupRepository
{
    public async Task<ProduccionProcesoLookup?> FindProcessAsync(long ordenProcesoId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                op.id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                opp.id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                op.estado AS OrdenEstado,
                opp.estado AS ProcesoEstado
            FROM produccion.orden_produccion_proceso opp
            INNER JOIN produccion.orden_produccion op ON op.id = opp.orden_produccion_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            WHERE opp.id = @OrdenProcesoId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ProduccionProcesoLookup>(
            new CommandDefinition(sql, new { OrdenProcesoId = ordenProcesoId }, cancellationToken: cancellationToken));
    }

    public async Task<ProduccionOrdenFinanceSnapshot?> FindOrderSnapshotAsync(long ordenProduccionId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                op.id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                op.lote_id AS LoteId,
                op.cantidad_pieles AS CantidadPieles,
                op.estado AS OrdenEstado,
                l.cliente_trae_lote AS ClienteTraeLote,
                l.costo_pieles_total AS CostoPielesTotal,
                op.fecha_fin_real AS FechaFinReal,
                pt.cantidad_pieles_buenas AS PielesBuenasFinales
            FROM produccion.orden_produccion op
            INNER JOIN produccion.lote l ON l.id = op.lote_id
            LEFT JOIN produccion.producto_terminado pt ON pt.orden_produccion_id = op.id
            WHERE op.id = @OrdenProduccionId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ProduccionOrdenFinanceSnapshot>(
            new CommandDefinition(sql, new { OrdenProduccionId = ordenProduccionId }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<ProduccionConsumoProcesoResumen>> ListConsumedCostByProcessAsync(
        long ordenProduccionId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                r.orden_produccion_id AS OrdenProduccionId,
                r.orden_proceso_id AS OrdenProcesoId,
                ISNULL(SUM(r.costo_total), 0) AS CostoInsumos
            FROM produccion.orden_consumo_real r
            WHERE r.orden_produccion_id = @OrdenProduccionId
            GROUP BY r.orden_produccion_id, r.orden_proceso_id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ProduccionConsumoProcesoResumen>(
            new CommandDefinition(sql, new { OrdenProduccionId = ordenProduccionId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<ProduccionConsumoOrdenResumen?> GetConsumedCostByOrderAsync(
        long ordenProduccionId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                r.orden_produccion_id AS OrdenProduccionId,
                ISNULL(SUM(r.costo_total), 0) AS CostoInsumos
            FROM produccion.orden_consumo_real r
            WHERE r.orden_produccion_id = @OrdenProduccionId
            GROUP BY r.orden_produccion_id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ProduccionConsumoOrdenResumen>(
            new CommandDefinition(sql, new { OrdenProduccionId = ordenProduccionId }, cancellationToken: cancellationToken));
    }

    public async Task<ProduccionConsumoOrdenResumen?> GetPlannedCostByOrderAsync(
        long ordenProduccionId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                p.orden_produccion_id AS OrdenProduccionId,
                ISNULL(SUM(p.cantidad_planificada * ISNULL(s.costo_promedio_actual, i.costo_promedio_actual)), 0) AS CostoInsumos
            FROM produccion.orden_consumo_planificado p
            INNER JOIN inventario.insumo i ON i.id = p.insumo_id
            LEFT JOIN inventario.stock_insumo s ON s.insumo_id = i.id
            WHERE p.orden_produccion_id = @OrdenProduccionId
            GROUP BY p.orden_produccion_id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ProduccionConsumoOrdenResumen>(
            new CommandDefinition(sql, new { OrdenProduccionId = ordenProduccionId }, cancellationToken: cancellationToken));
    }

    public async Task<decimal> GetTotalSkinsClosedInPeriodAsync(
        int anio,
        int mes,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT ISNULL(SUM(op.cantidad_pieles), 0)
            FROM produccion.orden_produccion op
            WHERE op.estado = 'FINALIZADA'
              AND op.fecha_fin_real IS NOT NULL
              AND YEAR(op.fecha_fin_real) = @Anio
              AND MONTH(op.fecha_fin_real) = @Mes;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<decimal>(
            new CommandDefinition(
                sql,
                new { Anio = anio, Mes = mes },
                cancellationToken: cancellationToken));
    }
}
