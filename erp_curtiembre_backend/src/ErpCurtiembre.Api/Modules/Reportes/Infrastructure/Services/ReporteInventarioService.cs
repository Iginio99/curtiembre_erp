using Dapper;
using ErpCurtiembre.Modules.Reportes.Application.DTOs;
using ErpCurtiembre.Modules.Reportes.Application.Ports;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Reportes.Infrastructure.Services;

public sealed class ReporteInventarioService(ISqlConnectionFactory connectionFactory) :
    IReporteStockActualService,
    IReporteKardexConsultaService,
    IReporteComprasProveedorService,
    IReporteConsumoProcesoService
{
    public async Task<IReadOnlyCollection<StockActualReporteDto>> GetCurrentStockAsync(
        StockActualReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                i.id AS InsumoId,
                i.codigo AS CodigoInsumo,
                i.nombre AS Insumo,
                i.tipo_bien AS TipoBien,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                ISNULL(s.cantidad_actual, 0) AS CantidadActual,
                i.stock_minimo AS StockMinimo,
                CASE
                    WHEN ISNULL(s.cantidad_actual, 0) = 0 THEN 'SIN_STOCK'
                    WHEN ISNULL(s.cantidad_actual, 0) <= i.stock_minimo THEN 'BAJO_STOCK'
                    ELSE 'STOCK_OK'
                END AS EstadoStock,
                ISNULL(s.costo_promedio_actual, i.costo_promedio_actual) AS CostoPromedioActual,
                CONVERT(DECIMAL(18,2), ISNULL(s.cantidad_actual, 0) * ISNULL(s.costo_promedio_actual, i.costo_promedio_actual)) AS ValorStock,
                i.activo AS Activo,
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
            ORDER BY i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<StockActualReporteDto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.TipoBien,
                    filters.Activo
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<KardexReporteDto>> GetKardexAsync(
        KardexReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                id AS Id,
                fecha_movimiento AS FechaMovimiento,
                codigo_insumo AS CodigoInsumo,
                insumo AS Insumo,
                tipo_movimiento AS TipoMovimiento,
                documento_tipo AS DocumentoTipo,
                documento_id AS DocumentoId,
                entrada AS Entrada,
                salida AS Salida,
                stock_actual AS StockActual,
                estado_stock AS EstadoStock,
                costo_unitario AS CostoUnitario,
                costo_total AS CostoTotal,
                usuario_responsable AS UsuarioResponsable
            FROM reportes.vw_kardex
            WHERE (@InsumoId IS NULL OR id IN (
                    SELECT k.id
                    FROM inventario.kardex_movimiento k
                    WHERE k.insumo_id = @InsumoId
                ))
              AND (@TipoMovimiento IS NULL OR tipo_movimiento = @TipoMovimiento)
              AND (@DocumentoTipo IS NULL OR documento_tipo = @DocumentoTipo)
              AND (
                    @Texto IS NULL OR
                    codigo_insumo LIKE @TextoLike OR
                    insumo LIKE @TextoLike OR
                    ISNULL(usuario_responsable, '') LIKE @TextoLike
                )
              AND (@FechaDesde IS NULL OR fecha_movimiento >= @FechaDesde)
              AND (@FechaHasta IS NULL OR fecha_movimiento <= @FechaHasta)
            ORDER BY fecha_movimiento DESC, id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<KardexReporteDto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.InsumoId,
                    filters.TipoMovimiento,
                    filters.DocumentoTipo,
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.FechaDesde,
                    filters.FechaHasta
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ComprasProveedorReporteDto>> GetBySupplierAsync(
        ComprasProveedorReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            WITH compras AS (
                SELECT
                    p.id AS ProveedorId,
                    p.ruc_documento AS RucDocumento,
                    p.razon_social AS Proveedor,
                    oc.id AS OrdenCompraId,
                    oc.fecha_emision AS FechaEmision,
                    det.cantidad_solicitada AS CantidadSolicitada,
                    det.cantidad_recibida AS CantidadRecibida,
                    ISNULL(det.cantidad_solicitada * det.costo_unitario_estimado, 0) AS MontoEstimado,
                    ISNULL(rec.monto_recibido, 0) AS MontoRecibido
                FROM inventario.orden_compra oc
                INNER JOIN inventario.proveedor p ON p.id = oc.proveedor_id
                INNER JOIN inventario.orden_compra_detalle det ON det.orden_compra_id = oc.id
                OUTER APPLY (
                    SELECT SUM(ed.cantidad * ed.costo_unitario) AS monto_recibido
                    FROM inventario.entrada_inventario_detalle ed
                    WHERE ed.orden_compra_detalle_id = det.id
                ) rec
                WHERE (@ProveedorId IS NULL OR oc.proveedor_id = @ProveedorId)
                  AND (@Estado IS NULL OR oc.estado = @Estado)
                  AND (@FechaDesde IS NULL OR oc.fecha_emision >= @FechaDesde)
                  AND (@FechaHasta IS NULL OR oc.fecha_emision <= @FechaHasta)
            )
            SELECT
                ProveedorId,
                RucDocumento,
                Proveedor,
                COUNT(DISTINCT OrdenCompraId) AS TotalOrdenes,
                SUM(CantidadSolicitada) AS CantidadSolicitadaTotal,
                SUM(CantidadRecibida) AS CantidadRecibidaTotal,
                SUM(MontoEstimado) AS MontoEstimadoTotal,
                SUM(MontoRecibido) AS MontoRecibidoTotal,
                MIN(FechaEmision) AS PrimeraCompra,
                MAX(FechaEmision) AS UltimaCompra
            FROM compras
            GROUP BY ProveedorId, RucDocumento, Proveedor
            ORDER BY Proveedor;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ComprasProveedorReporteDto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.ProveedorId,
                    filters.Estado,
                    filters.FechaDesde,
                    filters.FechaHasta
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ConsumoProcesoReporteDto>> GetProcessConsumptionAsync(
        ConsumoProcesoReporteFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                s.orden_produccion_id AS OrdenProduccionId,
                s.orden_proceso_id AS OrdenProcesoId,
                COUNT(DISTINCT s.id) AS TotalSalidas,
                COUNT(d.id) AS TotalItems,
                SUM(d.cantidad) AS CantidadConsumidaTotal,
                SUM(d.costo_total) AS CostoConsumidoTotal,
                MIN(s.fecha_salida) AS PrimeraSalida,
                MAX(s.fecha_salida) AS UltimaSalida
            FROM inventario.salida_inventario s
            INNER JOIN inventario.salida_inventario_detalle d ON d.salida_inventario_id = s.id
            WHERE s.tipo_salida = 'PROCESO'
              AND (@OrdenProduccionId IS NULL OR s.orden_produccion_id = @OrdenProduccionId)
              AND (@OrdenProcesoId IS NULL OR s.orden_proceso_id = @OrdenProcesoId)
              AND (@FechaDesde IS NULL OR s.fecha_salida >= @FechaDesde)
              AND (@FechaHasta IS NULL OR s.fecha_salida <= @FechaHasta)
            GROUP BY s.orden_produccion_id, s.orden_proceso_id
            ORDER BY MAX(s.fecha_salida) DESC, s.orden_proceso_id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ConsumoProcesoReporteDto>(
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
}
