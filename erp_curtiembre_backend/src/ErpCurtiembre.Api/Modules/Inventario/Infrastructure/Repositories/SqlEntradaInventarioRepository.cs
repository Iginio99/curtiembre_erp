using System.Data;
using Dapper;
using ErpCurtiembre.Modules.Alertas.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Modules.Inventario.Domain.Services;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;

public sealed class SqlEntradaInventarioRepository(
    ISqlConnectionFactory connectionFactory,
    InventarioDbContext dbContext,
    InboundStockCalculator inboundStockCalculator,
    IStockAlertIntegrationService stockAlertIntegrationService) : IEntradaInventarioRepository
{
    public async Task<long> RegisterStockInitialAsync(
        StockInitialRegistration registration,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            IsolationLevel.Serializable,
            cancellationToken);

        var entrada = new EntradaInventarioWriteModel
        {
            Codigo = registration.Codigo,
            TipoEntrada = "STOCK_INICIAL",
            FechaEntrada = registration.FechaEntrada,
            DocumentoSoporte = registration.DocumentoSoporte,
            Observacion = registration.Observacion,
            Estado = "REGISTRADA",
            CreadoPorUsuarioId = registration.ActorId
        };

        dbContext.EntradasInventario.Add(entrada);
        await dbContext.SaveChangesAsync(cancellationToken);

        foreach (var detail in registration.Detalles)
        {
            dbContext.EntradasInventarioDetalle.Add(new EntradaInventarioDetalleWriteModel
            {
                EntradaInventarioId = entrada.Id,
                InsumoId = detail.InsumoId,
                Cantidad = detail.Cantidad,
                CostoUnitario = detail.CostoUnitario,
                Observacion = detail.Observacion
            });

            var stock = await dbContext.StocksInsumo
                .SingleOrDefaultAsync(x => x.InsumoId == detail.InsumoId, cancellationToken);

            if (stock is null)
            {
                stock = new StockInsumoWriteModel
                {
                    InsumoId = detail.InsumoId
                };

                dbContext.StocksInsumo.Add(stock);
            }

            var insumo = await dbContext.Insumos
                .SingleAsync(x => x.Id == detail.InsumoId, cancellationToken);

            var projection = inboundStockCalculator.Calculate(
                stock.CantidadActual,
                stock.CostoPromedioActual,
                insumo.StockMinimo,
                detail.Cantidad,
                detail.CostoUnitario);

            stock.CantidadActual = projection.NuevoStock;
            stock.CostoPromedioActual = projection.NuevoCostoPromedio;
            stock.ActualizadoEn = registration.FechaEntrada;

            insumo.CostoPromedioActual = projection.NuevoCostoPromedio;
            insumo.ActualizadoEn = registration.FechaEntrada;
            insumo.ActualizadoPorUsuarioId = registration.ActorId;

            dbContext.KardexMovimientos.Add(new KardexMovimientoWriteModel
            {
                FechaMovimiento = registration.FechaEntrada,
                InsumoId = detail.InsumoId,
                TipoMovimiento = "STOCK_INICIAL",
                DocumentoTipo = "ENTRADA_INVENTARIO",
                DocumentoId = entrada.Id,
                Entrada = detail.Cantidad,
                Salida = 0,
                StockActual = projection.NuevoStock,
                EstadoStock = projection.EstadoStock,
                CostoUnitario = detail.CostoUnitario,
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
        return entrada.Id;
    }

    public async Task<long> RegisterFromPurchaseAsync(
        PurchaseEntryRegistration registration,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            IsolationLevel.Serializable,
            cancellationToken);

        var ordenCompra = await dbContext.OrdenesCompra
            .SingleOrDefaultAsync(x => x.Id == registration.OrdenCompraId, cancellationToken);

        if (ordenCompra is null)
        {
            throw new InvalidOperationException("La orden de compra no existe.");
        }

        if (!string.Equals(ordenCompra.Estado, "APROBADA", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(ordenCompra.Estado, "PARCIALMENTE_RECIBIDA", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("La orden de compra no admite nuevas recepciones.");
        }

        var entrada = new EntradaInventarioWriteModel
        {
            Codigo = registration.Codigo,
            TipoEntrada = "COMPRA",
            OrdenCompraId = registration.OrdenCompraId,
            FechaEntrada = registration.FechaEntrada,
            DocumentoSoporte = registration.DocumentoSoporte,
            Observacion = registration.Observacion,
            Estado = "REGISTRADA",
            CreadoPorUsuarioId = registration.ActorId
        };

        dbContext.EntradasInventario.Add(entrada);
        await dbContext.SaveChangesAsync(cancellationToken);

        foreach (var detail in registration.Detalles)
        {
            dbContext.EntradasInventarioDetalle.Add(new EntradaInventarioDetalleWriteModel
            {
                EntradaInventarioId = entrada.Id,
                OrdenCompraDetalleId = detail.OrdenCompraDetalleId,
                InsumoId = detail.InsumoId,
                Cantidad = detail.Cantidad,
                CostoUnitario = detail.CostoUnitario,
                Observacion = detail.Observacion
            });

            var ordenDetalle = await dbContext.OrdenesCompraDetalle
                .SingleOrDefaultAsync(
                    x => x.Id == detail.OrdenCompraDetalleId &&
                         x.OrdenCompraId == registration.OrdenCompraId &&
                         x.InsumoId == detail.InsumoId,
                    cancellationToken);

            if (ordenDetalle is null)
            {
                throw new InvalidOperationException(
                    $"El detalle de compra {detail.OrdenCompraDetalleId} no existe o no coincide con la orden.");
            }

            var saldoPendienteActual = ordenDetalle.CantidadSolicitada - ordenDetalle.CantidadRecibida;
            if (detail.Cantidad > saldoPendienteActual)
            {
                throw new InvalidOperationException(
                    $"La cantidad recibida del detalle {detail.OrdenCompraDetalleId} supera el saldo pendiente actual.");
            }

            ordenDetalle.CantidadRecibida = decimal.Round(ordenDetalle.CantidadRecibida + detail.Cantidad, 4);

            var stock = await dbContext.StocksInsumo
                .SingleOrDefaultAsync(x => x.InsumoId == detail.InsumoId, cancellationToken);

            if (stock is null)
            {
                stock = new StockInsumoWriteModel
                {
                    InsumoId = detail.InsumoId
                };

                dbContext.StocksInsumo.Add(stock);
            }

            var insumo = await dbContext.Insumos
                .SingleAsync(x => x.Id == detail.InsumoId, cancellationToken);

            var projection = inboundStockCalculator.Calculate(
                stock.CantidadActual,
                stock.CostoPromedioActual,
                insumo.StockMinimo,
                detail.Cantidad,
                detail.CostoUnitario);

            stock.CantidadActual = projection.NuevoStock;
            stock.CostoPromedioActual = projection.NuevoCostoPromedio;
            stock.ActualizadoEn = registration.FechaEntrada;

            insumo.CostoPromedioActual = projection.NuevoCostoPromedio;
            insumo.ActualizadoEn = registration.FechaEntrada;
            insumo.ActualizadoPorUsuarioId = registration.ActorId;

            dbContext.KardexMovimientos.Add(new KardexMovimientoWriteModel
            {
                FechaMovimiento = registration.FechaEntrada,
                InsumoId = detail.InsumoId,
                TipoMovimiento = "ENTRADA",
                DocumentoTipo = "ENTRADA_INVENTARIO",
                DocumentoId = entrada.Id,
                Entrada = detail.Cantidad,
                Salida = 0,
                StockActual = projection.NuevoStock,
                EstadoStock = projection.EstadoStock,
                CostoUnitario = detail.CostoUnitario,
                CostoTotal = projection.CostoTotal,
                UsuarioResponsableId = registration.ActorId,
                Observacion = detail.Observacion ?? registration.Observacion
            });
        }

        var detallesOrden = await dbContext.OrdenesCompraDetalle
            .Where(x => x.OrdenCompraId == registration.OrdenCompraId)
            .ToListAsync(cancellationToken);

        var saldoPendienteRestante = detallesOrden.Sum(x => x.CantidadSolicitada - x.CantidadRecibida);

        ordenCompra.Estado = saldoPendienteRestante <= 0
            ? "TOTALMENTE_RECIBIDA"
            : "PARCIALMENTE_RECIBIDA";
        ordenCompra.ActualizadoEn = registration.FechaEntrada;
        ordenCompra.ActualizadoPorUsuarioId = registration.ActorId;

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        await TrySyncLowStockAlertsAsync(
            registration.Detalles.Select(detail => detail.InsumoId).ToArray(),
            cancellationToken);
        return entrada.Id;
    }

    public async Task<EntradaInventario?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                e.id AS Id,
                e.codigo AS Codigo,
                e.tipo_entrada AS TipoEntrada,
                e.orden_compra_id AS OrdenCompraId,
                e.fecha_entrada AS FechaEntrada,
                e.documento_soporte AS DocumentoSoporte,
                e.observacion AS Observacion,
                e.estado AS Estado,
                e.creado_por_usuario_id AS CreadoPorUsuarioId,
                e.creado_en AS CreadoEn
            FROM inventario.entrada_inventario e
            WHERE e.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<EntradaInventario>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<EntradaInventarioDetalle>> ListDetailsAsync(long entradaId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.id AS Id,
                d.entrada_inventario_id AS EntradaInventarioId,
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
            FROM inventario.entrada_inventario_detalle d
            INNER JOIN inventario.insumo i ON i.id = d.insumo_id
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            INNER JOIN inventario.stock_insumo s ON s.insumo_id = d.insumo_id
            WHERE d.entrada_inventario_id = @EntradaId
            ORDER BY i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var details = await connection.QueryAsync<EntradaInventarioDetalle>(
            new CommandDefinition(sql, new { EntradaId = entradaId }, cancellationToken: cancellationToken));

        return details.ToArray();
    }

    private async Task TrySyncLowStockAlertsAsync(IReadOnlyCollection<long> insumoIds, CancellationToken cancellationToken)
    {
        try
        {
            await stockAlertIntegrationService.SyncLowStockAlertsAsync(insumoIds, cancellationToken);
        }
        catch
        {
            // Best-effort integration: el movimiento ya fue confirmado y no debe revertirse por una alerta.
        }
    }
}
