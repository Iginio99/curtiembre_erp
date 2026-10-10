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
                op.cantidad_pieles AS CantidadPieles,
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
                    p.orden_producto_id,
                    p.insumo_id,
                    SUM(p.cantidad_planificada) AS cantidad_planificada
                FROM produccion.orden_consumo_planificado p
                GROUP BY p.orden_produccion_id, p.orden_proceso_id, p.orden_producto_id, p.insumo_id
            ),
            actual AS (
                SELECT
                    r.orden_produccion_id,
                    r.orden_proceso_id,
                    r.orden_producto_id,
                    r.insumo_id,
                    SUM(r.cantidad_consumida) AS cantidad_real,
                    MAX(r.costo_unitario) AS costo_unitario,
                    SUM(r.costo_total) AS costo_total
                FROM produccion.orden_consumo_real r
                GROUP BY r.orden_produccion_id, r.orden_proceso_id, r.orden_producto_id, r.insumo_id
            ),
            deviation AS (
                SELECT
                    r.orden_produccion_id,
                    r.orden_proceso_id,
                    r.orden_producto_id,
                    r.insumo_id,
                    SUM(d.cantidad_desviacion) AS cantidad_desviacion
                FROM produccion.desviacion_consumo d
                INNER JOIN produccion.orden_consumo_real r ON r.id = d.orden_consumo_real_id
                GROUP BY r.orden_produccion_id, r.orden_proceso_id, r.orden_producto_id, r.insumo_id
            ),
            consumption_keys AS (
                SELECT orden_produccion_id, orden_proceso_id, orden_producto_id, insumo_id FROM planned
                UNION
                SELECT orden_produccion_id, orden_proceso_id, orden_producto_id, insumo_id FROM actual
            )
            SELECT
                op.id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                op.cantidad_pieles AS OrdenCantidadPieles,
                opp.id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                product.id AS OrdenProductoId,
                product.nombre AS ProductoNombre,
                product.color AS ProductoColor,
                CASE pp.codigo
                    WHEN 'RECURTIDO' THEN product.estado_recurtido
                    WHEN 'ACABADO' THEN product.estado_acabado
                    ELSE NULL
                END AS ProductoEstado,
                product.cantidad_pieles AS ProductoCantidadPieles,
                product.cantidad_lados AS ProductoCantidadLados,
                finished.cantidad_pieles AS ProductoCantidadPielesTerminadas,
                CASE pp.codigo
                    WHEN 'RECURTIDO' THEN product.kilos_recurtido
                    WHEN 'ACABADO' THEN product.kilos_acabado
                    ELSE NULL
                END AS ProductoPesoBaseKg,
                CASE pp.codigo
                    WHEN 'RECURTIDO' THEN product.inicio_recurtido
                    WHEN 'ACABADO' THEN product.inicio_acabado
                    ELSE NULL
                END AS ProductoInicio,
                CASE pp.codigo
                    WHEN 'RECURTIDO' THEN product.fin_recurtido
                    WHEN 'ACABADO' THEN product.fin_acabado
                    ELSE NULL
                END AS ProductoFin,
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
            INNER JOIN consumption_keys keys ON keys.orden_produccion_id=op.id AND keys.orden_proceso_id=opp.id
            INNER JOIN inventario.insumo i ON i.id=keys.insumo_id
            LEFT JOIN produccion.orden_producto product ON product.id=keys.orden_producto_id
            LEFT JOIN produccion.orden_producto_terminado finished ON finished.orden_producto_id=product.id
            LEFT JOIN planned ON planned.orden_produccion_id = op.id AND planned.orden_proceso_id = opp.id AND planned.insumo_id = i.id AND (planned.orden_producto_id=keys.orden_producto_id OR planned.orden_producto_id IS NULL AND keys.orden_producto_id IS NULL)
            LEFT JOIN actual ON actual.orden_produccion_id = op.id AND actual.orden_proceso_id = opp.id AND actual.insumo_id = i.id AND (actual.orden_producto_id=keys.orden_producto_id OR actual.orden_producto_id IS NULL AND keys.orden_producto_id IS NULL)
            LEFT JOIN deviation ON deviation.orden_produccion_id = op.id AND deviation.orden_proceso_id = opp.id AND deviation.insumo_id = i.id AND (deviation.orden_producto_id=keys.orden_producto_id OR deviation.orden_producto_id IS NULL AND keys.orden_producto_id IS NULL)
            WHERE (@OrdenProduccionId IS NULL OR op.id = @OrdenProduccionId)
              AND (@OrdenProcesoId IS NULL OR opp.id = @OrdenProcesoId)
            ORDER BY op.id, opp.secuencia, product.nombre, product.color, i.nombre, i.codigo;
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
                l.cliente_trae_lote AS ClienteTraeLote,
                CASE WHEN l.cliente_trae_lote = 1 THEN 0 ELSE ISNULL(l.costo_pieles_total, 0) END AS CostoPieles,
                ISNULL(SUM(ocr.costo_total), 0) AS CostoMaterialesReal,
                CAST((ISNULL(SUM(ocr.costo_total), 0) + CASE WHEN l.cliente_trae_lote = 1 THEN 0 ELSE ISNULL(l.costo_pieles_total, 0) END) / NULLIF(op.cantidad_pieles, 0) AS DECIMAL(18,2)) AS CostoMaterialesPorPiel,
                CAST((ISNULL(SUM(ocr.costo_total), 0) + CASE WHEN l.cliente_trae_lote = 1 THEN 0 ELSE ISNULL(l.costo_pieles_total, 0) END) / NULLIF(op.cantidad_pieles * 2.0, 0) AS DECIMAL(18,2)) AS CostoMaterialesPorLado
            FROM produccion.orden_produccion op
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            INNER JOIN produccion.lote l ON l.id = op.lote_id
            LEFT JOIN produccion.orden_consumo_real ocr ON ocr.orden_produccion_id = op.id
            WHERE (@OrdenProduccionId IS NULL OR op.id = @OrdenProduccionId)
            GROUP BY op.id, op.codigo, c.razon_social, l.codigo, op.cantidad_pieles, l.cliente_trae_lote, l.costo_pieles_total
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
            WITH actual AS (
                SELECT
                    orden_produccion_id,
                    orden_proceso_id,
                    orden_producto_id,
                    insumo_id,
                    SUM(cantidad_consumida) AS cantidad_consumida,
                    MAX(costo_unitario) AS costo_unitario,
                    SUM(costo_total) AS costo_total
                FROM produccion.orden_consumo_real
                GROUP BY orden_produccion_id, orden_proceso_id, orden_producto_id, insumo_id
            )
            SELECT
                op.id AS OrdenProduccionId,
                op.codigo AS CodigoOrden,
                opp.id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                product.id AS OrdenProductoId,
                product.nombre AS ProductoNombre,
                product.color AS ProductoColor,
                CASE pp.codigo WHEN 'RECURTIDO' THEN product.inicio_recurtido WHEN 'ACABADO' THEN product.inicio_acabado ELSE opp.fecha_inicio END AS FechaInicio,
                CASE pp.codigo WHEN 'RECURTIDO' THEN product.fin_recurtido WHEN 'ACABADO' THEN product.fin_acabado ELSE opp.fecha_fin END AS FechaFin,
                ISNULL(product.cantidad_pieles, op.cantidad_pieles) AS CantidadPieles,
                CASE pp.codigo WHEN 'RECURTIDO' THEN product.kilos_recurtido WHEN 'ACABADO' THEN product.kilos_acabado ELSE opp.peso_base_kg END AS PesoBaseKg,
                actual.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                COALESCE(planned.porcentaje, requested.porcentaje) AS Porcentaje,
                ISNULL(actual.cantidad_consumida, 0) AS CantidadConsumida,
                actual.costo_unitario AS CostoUnitario,
                ISNULL(actual.costo_total, 0) AS CostoMaterialesReal
            FROM produccion.orden_produccion op
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.orden_produccion_id = op.id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            LEFT JOIN actual ON actual.orden_produccion_id = op.id
                AND actual.orden_proceso_id = opp.id
            LEFT JOIN inventario.insumo i ON i.id = actual.insumo_id
            LEFT JOIN produccion.orden_producto product ON product.id=actual.orden_producto_id
            OUTER APPLY (
                SELECT TOP 1 ocp.porcentaje
                FROM produccion.orden_consumo_planificado ocp
                WHERE ocp.orden_produccion_id=op.id
                  AND ocp.orden_proceso_id=opp.id
                  AND ocp.insumo_id=actual.insumo_id
                  AND (ocp.orden_producto_id=actual.orden_producto_id
                       OR ocp.orden_producto_id IS NULL AND actual.orden_producto_id IS NULL)
                ORDER BY ocp.id DESC
            ) planned
            OUTER APPLY (
                SELECT TOP 1
                    COALESCE(
                        sd.porcentaje,
                        CAST(sd.cantidad_solicitada / NULLIF(opp.peso_base_kg, 0) AS decimal(9,4))
                    ) AS porcentaje
                FROM produccion.solicitud_insumo s
                INNER JOIN produccion.solicitud_insumo_detalle sd
                    ON sd.solicitud_insumo_id = s.id
                    AND sd.insumo_id = actual.insumo_id
                WHERE s.orden_produccion_id = op.id
                  AND s.orden_proceso_id = opp.id
                  AND (s.orden_producto_id=actual.orden_producto_id
                       OR s.orden_producto_id IS NULL AND actual.orden_producto_id IS NULL)
                ORDER BY s.solicitado_en DESC, s.id DESC
            ) requested
            WHERE (@OrdenProduccionId IS NULL OR op.id = @OrdenProduccionId)
            ORDER BY op.id DESC, opp.secuencia, product.nombre, product.color, i.nombre;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<CostosProcesoReporteItemDto>(
            new CommandDefinition(sql, new { filters.OrdenProduccionId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
