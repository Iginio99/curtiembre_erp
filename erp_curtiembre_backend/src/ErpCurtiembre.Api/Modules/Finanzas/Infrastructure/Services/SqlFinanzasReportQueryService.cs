using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Services;

public sealed class SqlFinanzasReportQueryService(ISqlConnectionFactory connectionFactory) : IFinanzasReportQueryService
{
    public async Task<IReadOnlyCollection<ReporteCostoOrdenItemDto>> ListCostoOrdenAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                co.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                c.razon_social AS ClienteRazonSocial,
                co.estado AS EstadoCosto,
                co.costo_total AS CostoTotal,
                co.costo_por_piel AS CostoPorPiel,
                co.calculado_en AS CalculadoEn
            FROM finanzas.costo_orden co
            INNER JOIN produccion.orden_produccion op ON op.id = co.orden_produccion_id
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            ORDER BY co.calculado_en DESC, co.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ReporteCostoOrdenItemDto>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ReporteCostoProcesoItemDto>> ListCostoProcesoAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                cp.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                cp.costo_insumos AS CostoInsumos,
                cp.costo_mano_obra AS CostoManoObra,
                cp.costo_total AS CostoTotal,
                cp.calculado_en AS CalculadoEn
            FROM finanzas.costo_proceso cp
            INNER JOIN produccion.orden_produccion op ON op.id = cp.orden_produccion_id
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = cp.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            ORDER BY cp.calculado_en DESC, cp.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ReporteCostoProcesoItemDto>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ReporteCostoClienteItemDto>> ListCostoClienteAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                c.id AS ClienteId,
                c.razon_social AS ClienteRazonSocial,
                COUNT(co.id) AS OrdenesCosteadas,
                SUM(co.costo_total) AS CostoTotal,
                AVG(co.costo_total) AS CostoPromedioOrden
            FROM finanzas.costo_orden co
            INNER JOIN produccion.orden_produccion op ON op.id = co.orden_produccion_id
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            GROUP BY c.id, c.razon_social
            ORDER BY c.razon_social;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ReporteCostoClienteItemDto>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ReporteIndirectoPeriodoItemDto>> ListIndirectosPeriodoAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                p.id AS PeriodoCostoId,
                p.anio AS Anio,
                p.mes AS Mes,
                p.estado AS Estado,
                ISNULL(SUM(ci.monto), 0) AS TotalIndirectos,
                COUNT(ci.id) AS TotalRegistros
            FROM finanzas.periodo_costo p
            LEFT JOIN finanzas.costo_indirecto ci ON ci.periodo_costo_id = p.id
            GROUP BY p.id, p.anio, p.mes, p.estado
            ORDER BY p.anio DESC, p.mes DESC, p.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ReporteIndirectoPeriodoItemDto>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ReporteRentabilidadItemDto>> ListRentabilidadAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                r.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                c.razon_social AS ClienteRazonSocial,
                r.precio_venta AS PrecioVenta,
                r.costo_total AS CostoTotal,
                r.utilidad AS Utilidad,
                r.margen_porcentaje AS MargenPorcentaje,
                r.calculado_en AS CalculadoEn
            FROM finanzas.rentabilidad_orden r
            INNER JOIN produccion.orden_produccion op ON op.id = r.orden_produccion_id
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            ORDER BY r.calculado_en DESC, r.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ReporteRentabilidadItemDto>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ReportePrecioSugeridoItemDto>> ListPrecioSugeridoAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                p.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                c.razon_social AS ClienteRazonSocial,
                p.costo_base_sin_igv AS CostoBaseSinIgv,
                p.margen_porcentaje AS MargenPorcentaje,
                p.precio_sugerido_sin_igv AS PrecioSugeridoSinIgv,
                p.igv_porcentaje AS IgvPorcentaje,
                p.precio_sugerido_con_igv AS PrecioSugeridoConIgv,
                p.calculado_en AS CalculadoEn
            FROM finanzas.precio_sugerido p
            INNER JOIN produccion.orden_produccion op ON op.id = p.orden_produccion_id
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            ORDER BY p.calculado_en DESC, p.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ReportePrecioSugeridoItemDto>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));
        return items.ToArray();
    }
}
