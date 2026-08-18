using Dapper;
using ErpCurtiembre.Modules.Alertas.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Modules.Inventario.Domain.Services;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;

public sealed class SqlSalidaInventarioRepository(
    ISqlConnectionFactory connectionFactory,
    InventarioDbContext dbContext,
    OutboundStockCalculator outboundStockCalculator,
    IStockAlertIntegrationService stockAlertIntegrationService) : ISalidaInventarioRepository
{
    public async Task<long> RegisterAsync(SalidaInventarioRegistration registration, CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            System.Data.IsolationLevel.Serializable,
            cancellationToken);

        var salida = new SalidaInventarioWriteModel
        {
            Codigo = registration.Codigo,
            TipoSalida = registration.TipoSalida,
            OrdenProduccionId = registration.OrdenProduccionId,
            OrdenProcesoId = registration.OrdenProcesoId,
            FechaSalida = registration.FechaSalida,
            Motivo = registration.Motivo,
            Observacion = registration.Observacion,
            Estado = "REGISTRADA",
            CreadoPorUsuarioId = registration.ActorId
        };

        dbContext.SalidasInventario.Add(salida);
        await dbContext.SaveChangesAsync(cancellationToken);

        foreach (var detail in registration.Detalles)
        {
            var stock = await dbContext.StocksInsumo
                .SingleOrDefaultAsync(x => x.InsumoId == detail.InsumoId, cancellationToken);

            if (stock is null)
            {
                throw new InvalidOperationException($"El insumo {detail.InsumoId} no tiene stock inicializado.");
            }

            var insumo = await dbContext.Insumos
                .SingleAsync(x => x.Id == detail.InsumoId, cancellationToken);

            var projection = outboundStockCalculator.Calculate(
                stock.CantidadActual,
                stock.CostoPromedioActual,
                insumo.StockMinimo,
                detail.Cantidad);

            dbContext.SalidasInventarioDetalle.Add(new SalidaInventarioDetalleWriteModel
            {
                SalidaInventarioId = salida.Id,
                InsumoId = detail.InsumoId,
                Cantidad = detail.Cantidad,
                CostoUnitario = projection.CostoUnitario,
                Observacion = detail.Observacion
            });

            stock.CantidadActual = projection.NuevoStock;
            stock.ActualizadoEn = registration.FechaSalida;

            dbContext.KardexMovimientos.Add(new KardexMovimientoWriteModel
            {
                FechaMovimiento = registration.FechaSalida,
                InsumoId = detail.InsumoId,
                TipoMovimiento = registration.TipoSalida switch
                {
                    "AJUSTE_NEGATIVO" => "AJUSTE_NEGATIVO",
                    "DEVOLUCION_PROVEEDOR" => "DEVOLUCION_PROVEEDOR",
                    _ => "SALIDA"
                },
                DocumentoTipo = "SALIDA_INVENTARIO",
                DocumentoId = salida.Id,
                Entrada = 0,
                Salida = detail.Cantidad,
                StockActual = projection.NuevoStock,
                EstadoStock = projection.EstadoStock,
                CostoUnitario = projection.CostoUnitario,
                CostoTotal = projection.CostoTotal,
                UsuarioResponsableId = registration.ActorId,
                Observacion = detail.Observacion ?? registration.Observacion
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        await TrySyncLowStockAlertsAsync(
            registration.Detalles.Select(detail => detail.InsumoId).ToArray(),
            cancellationToken);
        return salida.Id;
    }

    public async Task<SalidaInventario?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                s.id AS Id,
                s.codigo AS Codigo,
                s.tipo_salida AS TipoSalida,
                s.orden_produccion_id AS OrdenProduccionId,
                s.orden_proceso_id AS OrdenProcesoId,
                s.fecha_salida AS FechaSalida,
                s.motivo AS Motivo,
                s.observacion AS Observacion,
                s.estado AS Estado,
                s.creado_por_usuario_id AS CreadoPorUsuarioId,
                s.creado_en AS CreadoEn,
                COUNT(d.id) AS TotalItems,
                ISNULL(SUM(d.cantidad), 0) AS CantidadTotal,
                ISNULL(SUM(d.costo_total), 0) AS MontoTotal
            FROM inventario.salida_inventario s
            LEFT JOIN inventario.salida_inventario_detalle d ON d.salida_inventario_id = s.id
            WHERE s.id = @Id
            GROUP BY
                s.id,
                s.codigo,
                s.tipo_salida,
                s.orden_produccion_id,
                s.orden_proceso_id,
                s.fecha_salida,
                s.motivo,
                s.observacion,
                s.estado,
                s.creado_por_usuario_id,
                s.creado_en;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<SalidaInventario>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<SalidaInventarioDetalle>> ListDetailsAsync(long salidaId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.id AS Id,
                d.salida_inventario_id AS SalidaInventarioId,
                d.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                d.cantidad AS Cantidad,
                d.costo_unitario AS CostoUnitario,
                d.costo_total AS CostoTotal,
                s.cantidad_actual AS StockActual,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                d.observacion AS Observacion
            FROM inventario.salida_inventario_detalle d
            INNER JOIN inventario.insumo i ON i.id = d.insumo_id
            INNER JOIN inventario.stock_insumo s ON s.insumo_id = d.insumo_id
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            WHERE d.salida_inventario_id = @SalidaId
            ORDER BY i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var details = await connection.QueryAsync<SalidaInventarioDetalle>(
            new CommandDefinition(sql, new { SalidaId = salidaId }, cancellationToken: cancellationToken));

        return details.ToArray();
    }

    public async Task<IReadOnlyCollection<SalidaInventario>> ListAsync(SalidaInventarioFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                s.id AS Id,
                s.codigo AS Codigo,
                s.tipo_salida AS TipoSalida,
                s.orden_produccion_id AS OrdenProduccionId,
                s.orden_proceso_id AS OrdenProcesoId,
                s.fecha_salida AS FechaSalida,
                s.motivo AS Motivo,
                s.observacion AS Observacion,
                s.estado AS Estado,
                s.creado_por_usuario_id AS CreadoPorUsuarioId,
                s.creado_en AS CreadoEn,
                COUNT(d.id) AS TotalItems,
                ISNULL(SUM(d.cantidad), 0) AS CantidadTotal,
                ISNULL(SUM(d.costo_total), 0) AS MontoTotal
            FROM inventario.salida_inventario s
            LEFT JOIN inventario.salida_inventario_detalle d ON d.salida_inventario_id = s.id
            WHERE (
                    @Texto IS NULL OR
                    s.codigo LIKE @TextoLike OR
                    s.motivo LIKE @TextoLike OR
                    s.observacion LIKE @TextoLike
                )
              AND (@TipoSalida IS NULL OR s.tipo_salida = @TipoSalida)
              AND (@FechaDesde IS NULL OR s.fecha_salida >= @FechaDesde)
              AND (@FechaHasta IS NULL OR s.fecha_salida <= @FechaHasta)
            GROUP BY
                s.id,
                s.codigo,
                s.tipo_salida,
                s.orden_produccion_id,
                s.orden_proceso_id,
                s.fecha_salida,
                s.motivo,
                s.observacion,
                s.estado,
                s.creado_por_usuario_id,
                s.creado_en
            ORDER BY s.fecha_salida DESC, s.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<SalidaInventario>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.TipoSalida,
                    FechaDesde = filters.FechaDesde,
                    FechaHasta = filters.FechaHasta
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    private async Task TrySyncLowStockAlertsAsync(IReadOnlyCollection<long> insumoIds, CancellationToken cancellationToken)
    {
        try
        {
            await stockAlertIntegrationService.SyncLowStockAlertsAsync(insumoIds, cancellationToken);
        }
        catch
        {
            // Best-effort integration: la salida no debe fallar si la alerta no pudo sincronizarse.
        }
    }
}
