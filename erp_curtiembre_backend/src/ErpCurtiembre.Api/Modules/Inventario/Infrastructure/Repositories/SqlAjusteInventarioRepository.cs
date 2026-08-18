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

public sealed class SqlAjusteInventarioRepository(
    ISqlConnectionFactory connectionFactory,
    InventarioDbContext dbContext,
    InboundStockCalculator inboundStockCalculator,
    OutboundStockCalculator outboundStockCalculator,
    IStockAlertIntegrationService stockAlertIntegrationService) : IAjusteInventarioRepository
{
    public async Task<long> RegisterAsync(AjusteInventarioRegistration registration, CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            System.Data.IsolationLevel.Serializable,
            cancellationToken);

        var ajuste = new AjusteInventarioWriteModel
        {
            Codigo = registration.Codigo,
            TipoAjuste = registration.TipoAjuste,
            FechaAjuste = registration.FechaAjuste,
            Motivo = registration.Motivo,
            Observacion = registration.Observacion,
            UsuarioResponsableId = registration.UsuarioResponsableId
        };

        dbContext.AjustesInventario.Add(ajuste);
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

            decimal? costoUnitarioPersistido;
            decimal costoTotal;
            decimal nuevoStock;
            string estadoStock;

            if (string.Equals(registration.TipoAjuste, "POSITIVO", StringComparison.OrdinalIgnoreCase))
            {
                if (detail.CostoUnitario is null)
                {
                    throw new InvalidOperationException($"El insumo {detail.InsumoId} requiere costo unitario para ajuste positivo.");
                }

                var projection = inboundStockCalculator.Calculate(
                    stock.CantidadActual,
                    stock.CostoPromedioActual,
                    insumo.StockMinimo,
                    detail.Cantidad,
                    detail.CostoUnitario.Value);

                stock.CantidadActual = projection.NuevoStock;
                stock.CostoPromedioActual = projection.NuevoCostoPromedio;
                stock.ActualizadoEn = registration.FechaAjuste;

                insumo.CostoPromedioActual = projection.NuevoCostoPromedio;
                insumo.ActualizadoEn = registration.FechaAjuste;
                insumo.ActualizadoPorUsuarioId = registration.UsuarioResponsableId;

                costoUnitarioPersistido = detail.CostoUnitario.Value;
                costoTotal = projection.CostoTotal;
                nuevoStock = projection.NuevoStock;
                estadoStock = projection.EstadoStock;

                dbContext.KardexMovimientos.Add(new KardexMovimientoWriteModel
                {
                    FechaMovimiento = registration.FechaAjuste,
                    InsumoId = detail.InsumoId,
                    TipoMovimiento = "AJUSTE_POSITIVO",
                    DocumentoTipo = "AJUSTE_INVENTARIO",
                    DocumentoId = ajuste.Id,
                    Entrada = detail.Cantidad,
                    Salida = 0,
                    StockActual = nuevoStock,
                    EstadoStock = estadoStock,
                    CostoUnitario = costoUnitarioPersistido.Value,
                    CostoTotal = costoTotal,
                    UsuarioResponsableId = registration.UsuarioResponsableId,
                    Observacion = registration.Observacion ?? registration.Motivo
                });
            }
            else
            {
                var projection = outboundStockCalculator.Calculate(
                    stock.CantidadActual,
                    stock.CostoPromedioActual,
                    insumo.StockMinimo,
                    detail.Cantidad);

                stock.CantidadActual = projection.NuevoStock;
                stock.ActualizadoEn = registration.FechaAjuste;

                costoUnitarioPersistido = projection.CostoUnitario;
                costoTotal = projection.CostoTotal;
                nuevoStock = projection.NuevoStock;
                estadoStock = projection.EstadoStock;

                dbContext.KardexMovimientos.Add(new KardexMovimientoWriteModel
                {
                    FechaMovimiento = registration.FechaAjuste,
                    InsumoId = detail.InsumoId,
                    TipoMovimiento = "AJUSTE_NEGATIVO",
                    DocumentoTipo = "AJUSTE_INVENTARIO",
                    DocumentoId = ajuste.Id,
                    Entrada = 0,
                    Salida = detail.Cantidad,
                    StockActual = nuevoStock,
                    EstadoStock = estadoStock,
                    CostoUnitario = costoUnitarioPersistido.Value,
                    CostoTotal = costoTotal,
                    UsuarioResponsableId = registration.UsuarioResponsableId,
                    Observacion = registration.Observacion ?? registration.Motivo
                });
            }

            dbContext.AjustesInventarioDetalle.Add(new AjusteInventarioDetalleWriteModel
            {
                AjusteInventarioId = ajuste.Id,
                InsumoId = detail.InsumoId,
                Cantidad = detail.Cantidad,
                CostoUnitario = costoUnitarioPersistido
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        await TrySyncLowStockAlertsAsync(
            registration.Detalles.Select(detail => detail.InsumoId).ToArray(),
            cancellationToken);
        return ajuste.Id;
    }

    public async Task<AjusteInventario?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                a.id AS Id,
                a.codigo AS Codigo,
                a.tipo_ajuste AS TipoAjuste,
                a.fecha_ajuste AS FechaAjuste,
                a.motivo AS Motivo,
                a.observacion AS Observacion,
                a.usuario_responsable_id AS UsuarioResponsableId,
                COUNT(d.id) AS TotalItems,
                ISNULL(SUM(d.cantidad), 0) AS CantidadTotal,
                ISNULL(SUM(ISNULL(d.costo_unitario, 0) * d.cantidad), 0) AS MontoTotal
            FROM inventario.ajuste_inventario a
            LEFT JOIN inventario.ajuste_inventario_detalle d ON d.ajuste_inventario_id = a.id
            WHERE a.id = @Id
            GROUP BY
                a.id,
                a.codigo,
                a.tipo_ajuste,
                a.fecha_ajuste,
                a.motivo,
                a.observacion,
                a.usuario_responsable_id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<AjusteInventario>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<AjusteInventarioDetalle>> ListDetailsAsync(long ajusteId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.id AS Id,
                d.ajuste_inventario_id AS AjusteInventarioId,
                d.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                d.cantidad AS Cantidad,
                d.costo_unitario AS CostoUnitario,
                ISNULL(d.costo_unitario, 0) * d.cantidad AS CostoTotal,
                s.cantidad_actual AS StockActual,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre
            FROM inventario.ajuste_inventario_detalle d
            INNER JOIN inventario.insumo i ON i.id = d.insumo_id
            INNER JOIN inventario.stock_insumo s ON s.insumo_id = d.insumo_id
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            WHERE d.ajuste_inventario_id = @AjusteId
            ORDER BY i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<AjusteInventarioDetalle>(
            new CommandDefinition(sql, new { AjusteId = ajusteId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<AjusteInventario>> ListAsync(AjusteInventarioFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                a.id AS Id,
                a.codigo AS Codigo,
                a.tipo_ajuste AS TipoAjuste,
                a.fecha_ajuste AS FechaAjuste,
                a.motivo AS Motivo,
                a.observacion AS Observacion,
                a.usuario_responsable_id AS UsuarioResponsableId,
                COUNT(d.id) AS TotalItems,
                ISNULL(SUM(d.cantidad), 0) AS CantidadTotal,
                ISNULL(SUM(ISNULL(d.costo_unitario, 0) * d.cantidad), 0) AS MontoTotal
            FROM inventario.ajuste_inventario a
            LEFT JOIN inventario.ajuste_inventario_detalle d ON d.ajuste_inventario_id = a.id
            WHERE (
                    @Texto IS NULL OR
                    a.codigo LIKE @TextoLike OR
                    a.motivo LIKE @TextoLike OR
                    a.observacion LIKE @TextoLike
                )
              AND (@TipoAjuste IS NULL OR a.tipo_ajuste = @TipoAjuste)
              AND (@FechaDesde IS NULL OR a.fecha_ajuste >= @FechaDesde)
              AND (@FechaHasta IS NULL OR a.fecha_ajuste <= @FechaHasta)
            GROUP BY
                a.id,
                a.codigo,
                a.tipo_ajuste,
                a.fecha_ajuste,
                a.motivo,
                a.observacion,
                a.usuario_responsable_id
            ORDER BY a.fecha_ajuste DESC, a.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<AjusteInventario>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.TipoAjuste,
                    filters.FechaDesde,
                    filters.FechaHasta
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
            // Best-effort integration: el ajuste ya fue confirmado y no debe revertirse por una alerta.
        }
    }
}
