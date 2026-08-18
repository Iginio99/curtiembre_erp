using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlProduccionReportQueryRepository(ISqlConnectionFactory connectionFactory) : IProduccionReportQueryRepository
{
    public async Task<IReadOnlyCollection<OrdenesActivasReporteItemDto>> ListActiveOrdersAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                op.id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                c.razon_social AS Cliente,
                l.codigo AS CodigoLote,
                CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END AS Responsable,
                op.fecha_inicio_real AS FechaInicioReal,
                op.fecha_fin_estimada AS FechaFinEstimada,
                op.estado AS Estado
            FROM produccion.orden_produccion op
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            INNER JOIN produccion.lote l ON l.id = op.lote_id
            LEFT JOIN seguridad.usuario u ON u.id = op.responsable_usuario_id
            WHERE op.estado IN ('PROGRAMADA','EN_PROCESO')
            ORDER BY op.fecha_fin_estimada, op.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<OrdenesActivasReporteItemDto>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<OrdenesPorClienteReporteItemDto>> ListOrdersByClientAsync(
        OrdenesPorClienteReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                op.id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                c.id AS ClienteId,
                c.razon_social AS Cliente,
                l.codigo AS CodigoLote,
                op.cantidad_pieles AS CantidadPieles,
                op.fecha_inicio_real AS FechaInicioReal,
                op.fecha_fin_estimada AS FechaFinEstimada,
                op.fecha_fin_real AS FechaFinReal,
                op.estado AS Estado
            FROM produccion.orden_produccion op
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            INNER JOIN produccion.lote l ON l.id = op.lote_id
            WHERE (@ClienteId IS NULL OR c.id = @ClienteId)
              AND (@Estado IS NULL OR op.estado = @Estado)
              AND (@FechaDesde IS NULL OR op.creado_en >= @FechaDesde)
              AND (@FechaHasta IS NULL OR op.creado_en <= @FechaHasta)
            ORDER BY c.razon_social, op.creado_en DESC, op.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<OrdenesPorClienteReporteItemDto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.ClienteId,
                    filters.Estado,
                    filters.FechaDesde,
                    filters.FechaHasta
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ConsumoPorProcesoReporteItemDto>> ListConsumptionByProcessAsync(
        ConsumoPorProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            WITH planned AS (
                SELECT
                    p.orden_produccion_id,
                    p.orden_proceso_id,
                    p.insumo_id,
                    SUM(p.cantidad_planificada) AS cantidad_planificada
                FROM produccion.orden_consumo_planificado p
                GROUP BY p.orden_produccion_id, p.orden_proceso_id, p.insumo_id
            ),
            actual AS (
                SELECT
                    r.orden_produccion_id,
                    r.orden_proceso_id,
                    r.insumo_id,
                    SUM(r.cantidad_consumida) AS cantidad_real,
                    MAX(r.costo_unitario) AS costo_unitario,
                    SUM(r.costo_total) AS costo_total
                FROM produccion.orden_consumo_real r
                GROUP BY r.orden_produccion_id, r.orden_proceso_id, r.insumo_id
            ),
            deviation AS (
                SELECT
                    r.orden_produccion_id,
                    r.orden_proceso_id,
                    r.insumo_id,
                    SUM(d.cantidad_desviacion) AS cantidad_desviacion
                FROM produccion.desviacion_consumo d
                INNER JOIN produccion.orden_consumo_real r ON r.id = d.orden_consumo_real_id
                GROUP BY r.orden_produccion_id, r.orden_proceso_id, r.insumo_id
            )
            SELECT
                op.id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                opp.id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                i.id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                ISNULL(planned.cantidad_planificada, 0) AS CantidadPlanificada,
                ISNULL(actual.cantidad_real, 0) AS CantidadReal,
                ISNULL(deviation.cantidad_desviacion, CASE WHEN ISNULL(actual.cantidad_real, 0) > ISNULL(planned.cantidad_planificada, 0) THEN ISNULL(actual.cantidad_real, 0) - ISNULL(planned.cantidad_planificada, 0) ELSE 0 END) AS CantidadDesviacion,
                actual.costo_unitario AS CostoUnitario,
                ISNULL(actual.costo_total, 0) AS CostoTotal
            FROM produccion.orden_produccion op
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.orden_produccion_id = op.id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            INNER JOIN inventario.insumo i ON i.id IN (
                SELECT x.insumo_id
                FROM produccion.orden_consumo_planificado x
                WHERE x.orden_produccion_id = op.id AND x.orden_proceso_id = opp.id
                UNION
                SELECT y.insumo_id
                FROM produccion.orden_consumo_real y
                WHERE y.orden_produccion_id = op.id AND y.orden_proceso_id = opp.id
            )
            LEFT JOIN planned ON planned.orden_produccion_id = op.id AND planned.orden_proceso_id = opp.id AND planned.insumo_id = i.id
            LEFT JOIN actual ON actual.orden_produccion_id = op.id AND actual.orden_proceso_id = opp.id AND actual.insumo_id = i.id
            LEFT JOIN deviation ON deviation.orden_produccion_id = op.id AND deviation.orden_proceso_id = opp.id AND deviation.insumo_id = i.id
            WHERE (@OrdenProduccionId IS NULL OR op.id = @OrdenProduccionId)
              AND (@OrdenProcesoId IS NULL OR opp.id = @OrdenProcesoId)
            ORDER BY op.id, opp.secuencia, i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ConsumoPorProcesoReporteItemDto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.OrdenProduccionId,
                    filters.OrdenProcesoId
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<MermaReporteItemDto>> ListMermaAsync(
        MermaReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                m.id AS Id,
                m.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                m.orden_proceso_id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                m.cantidad_perdida AS CantidadPerdida,
                m.motivo AS Motivo,
                m.registrado_en AS RegistradoEn,
                CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END AS Responsable
            FROM produccion.merma_proceso m
            INNER JOIN produccion.orden_produccion op ON op.id = m.orden_produccion_id
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = m.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            LEFT JOIN seguridad.usuario u ON u.id = m.registrado_por_usuario_id
            WHERE (@OrdenProduccionId IS NULL OR m.orden_produccion_id = @OrdenProduccionId)
              AND (@OrdenProcesoId IS NULL OR m.orden_proceso_id = @OrdenProcesoId)
              AND (@FechaDesde IS NULL OR m.registrado_en >= @FechaDesde)
              AND (@FechaHasta IS NULL OR m.registrado_en <= @FechaHasta)
            ORDER BY m.registrado_en DESC, m.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<MermaReporteItemDto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.OrdenProduccionId,
                    filters.OrdenProcesoId,
                    filters.FechaDesde,
                    filters.FechaHasta
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<TiemposProcesoReporteItemDto>> ListProcessTimesAsync(
        TiemposProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                op.id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                opp.id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                opp.fecha_inicio AS FechaInicio,
                opp.fecha_fin AS FechaFin,
                opp.dias_reales AS DiasReales,
                opp.estado AS Estado,
                CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END AS Responsable
            FROM produccion.orden_produccion_proceso opp
            INNER JOIN produccion.orden_produccion op ON op.id = opp.orden_produccion_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            LEFT JOIN seguridad.usuario u ON u.id = opp.responsable_usuario_id
            WHERE (@OrdenProduccionId IS NULL OR op.id = @OrdenProduccionId)
              AND (@OrdenProcesoId IS NULL OR opp.id = @OrdenProcesoId)
              AND (@Estado IS NULL OR opp.estado = @Estado)
            ORDER BY op.id, opp.secuencia;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<TiemposProcesoReporteItemDto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.OrdenProduccionId,
                    filters.OrdenProcesoId,
                    filters.Estado
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<CostosOrdenReporteItemDto>> ListCostsByOrderAsync(
        CostosOrdenReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                op.id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                c.razon_social AS Cliente,
                l.codigo AS CodigoLote,
                op.cantidad_pieles AS CantidadPieles,
                CAST(op.cantidad_pieles * 2.0 AS DECIMAL(18,2)) AS CantidadLados,
                ISNULL(SUM(ocr.costo_total), 0) AS CostoMaterialesReal,
                CAST(ISNULL(SUM(ocr.costo_total), 0) / NULLIF(op.cantidad_pieles, 0) AS DECIMAL(18,2)) AS CostoMaterialesPorPiel,
                CAST(ISNULL(SUM(ocr.costo_total), 0) / NULLIF(op.cantidad_pieles * 2.0, 0) AS DECIMAL(18,2)) AS CostoMaterialesPorLado
            FROM produccion.orden_produccion op
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            INNER JOIN produccion.lote l ON l.id = op.lote_id
            LEFT JOIN produccion.orden_consumo_real ocr ON ocr.orden_produccion_id = op.id
            WHERE (@OrdenProduccionId IS NULL OR op.id = @OrdenProduccionId)
            GROUP BY op.id, op.codigo, c.razon_social, l.codigo, op.cantidad_pieles
            ORDER BY op.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<CostosOrdenReporteItemDto>(
            new CommandDefinition(sql, new { filters.OrdenProduccionId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<CostosProcesoReporteItemDto>> ListCostsByProcessAsync(
        CostosOrdenReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                op.id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                opp.id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                ISNULL(SUM(ocr.costo_total), 0) AS CostoMaterialesReal
            FROM produccion.orden_produccion op
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.orden_produccion_id = op.id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            LEFT JOIN produccion.orden_consumo_real ocr ON ocr.orden_produccion_id = op.id
                AND ocr.orden_proceso_id = opp.id
            WHERE (@OrdenProduccionId IS NULL OR op.id = @OrdenProduccionId)
            GROUP BY op.id, op.codigo, opp.id, pp.codigo, pp.nombre, opp.secuencia
            ORDER BY op.id DESC, opp.secuencia;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<CostosProcesoReporteItemDto>(
            new CommandDefinition(sql, new { filters.OrdenProduccionId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
