using System.Data;
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

public sealed class SqlInventarioFisicoRepository(
    ISqlConnectionFactory connectionFactory,
    InventarioDbContext dbContext,
    InboundStockCalculator inboundStockCalculator,
    OutboundStockCalculator outboundStockCalculator,
    IStockAlertIntegrationService stockAlertIntegrationService) : IInventarioFisicoRepository
{
    public async Task<long> CreateAsync(InventarioFisicoRegistration registration, CancellationToken cancellationToken)
    {
        var hasOpenInventory = await dbContext.InventariosFisicos
            .AnyAsync(x => x.Estado == "ABIERTO", cancellationToken);

        if (hasOpenInventory)
        {
            throw new InvalidOperationException("Ya existe un inventario fisico abierto.");
        }

        var samePeriodExists = await dbContext.InventariosFisicos
            .AnyAsync(
                x => x.PeriodoAnio == registration.PeriodoAnio &&
                     x.PeriodoMes == registration.PeriodoMes &&
                     x.Estado != "ANULADO",
                cancellationToken);

        if (samePeriodExists)
        {
            throw new InvalidOperationException("Ya existe un inventario fisico registrado para ese periodo.");
        }

        var entity = new InventarioFisicoWriteModel
        {
            Codigo = registration.Codigo,
            FechaInicio = registration.FechaInicio,
            PeriodoAnio = registration.PeriodoAnio,
            PeriodoMes = registration.PeriodoMes,
            Estado = "ABIERTO",
            EjecutadoPorUsuarioId = registration.EjecutadoPorUsuarioId,
            Observacion = registration.Observacion
        };

        dbContext.InventariosFisicos.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task RegisterCountsAsync(
        long inventarioFisicoId,
        IReadOnlyCollection<InventarioFisicoCountRegistrationDetail> details,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            IsolationLevel.Serializable,
            cancellationToken);

        var inventarioFisico = await dbContext.InventariosFisicos
            .SingleOrDefaultAsync(x => x.Id == inventarioFisicoId, cancellationToken);

        if (inventarioFisico is null)
        {
            throw new InvalidOperationException("El inventario fisico no existe.");
        }

        if (!string.Equals(inventarioFisico.Estado, "ABIERTO", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Solo se puede registrar conteo en un inventario fisico abierto.");
        }

        foreach (var detail in details)
        {
            var stockActual = await dbContext.StocksInsumo
                .Where(x => x.InsumoId == detail.InsumoId)
                .Select(x => x.CantidadActual)
                .SingleOrDefaultAsync(cancellationToken);

            var existingDetail = await dbContext.InventariosFisicosDetalle
                .SingleOrDefaultAsync(
                    x => x.InventarioFisicoId == inventarioFisicoId && x.InsumoId == detail.InsumoId,
                    cancellationToken);

            if (existingDetail is null)
            {
                dbContext.InventariosFisicosDetalle.Add(new InventarioFisicoDetalleWriteModel
                {
                    InventarioFisicoId = inventarioFisicoId,
                    InsumoId = detail.InsumoId,
                    StockSistema = stockActual,
                    StockContado = detail.StockContado,
                    Observacion = detail.Observacion
                });
            }
            else
            {
                existingDetail.StockSistema = stockActual;
                existingDetail.StockContado = detail.StockContado;
                existingDetail.Observacion = detail.Observacion;
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task CloseAsync(InventarioFisicoCloseRegistration registration, CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(
            IsolationLevel.Serializable,
            cancellationToken);

        var inventarioFisico = await dbContext.InventariosFisicos
            .SingleOrDefaultAsync(x => x.Id == registration.InventarioFisicoId, cancellationToken);

        if (inventarioFisico is null)
        {
            throw new InvalidOperationException("El inventario fisico no existe.");
        }

        if (!string.Equals(inventarioFisico.Estado, "ABIERTO", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Solo se puede cerrar un inventario fisico abierto.");
        }

        var details = await dbContext.InventariosFisicosDetalle
            .Where(x => x.InventarioFisicoId == registration.InventarioFisicoId)
            .ToListAsync(cancellationToken);

        if (details.Count == 0)
        {
            throw new InvalidOperationException("Debes registrar al menos un conteo antes de cerrar el inventario fisico.");
        }

        var detallesConDiferenciaPositiva = details
            .Where(x => x.StockContado > x.StockSistema)
            .ToList();

        var detallesConDiferenciaNegativa = details
            .Where(x => x.StockContado < x.StockSistema)
            .ToList();

        AjusteInventarioWriteModel? ajustePositivo = null;
        AjusteInventarioWriteModel? ajusteNegativo = null;

        var motivoBase = $"Ajuste por cierre de inventario fisico {inventarioFisico.Codigo}";
        var observacionBase = registration.Observacion ?? inventarioFisico.Observacion;

        if (detallesConDiferenciaPositiva.Count > 0)
        {
            if (string.IsNullOrWhiteSpace(registration.CodigoAjustePositivo))
            {
                throw new InvalidOperationException("No se genero el correlativo para el ajuste positivo.");
            }

            ajustePositivo = new AjusteInventarioWriteModel
            {
                Codigo = registration.CodigoAjustePositivo,
                TipoAjuste = "POSITIVO",
                FechaAjuste = registration.FechaCierre,
                Motivo = motivoBase,
                Observacion = observacionBase,
                UsuarioResponsableId = registration.UsuarioResponsableId
            };

            dbContext.AjustesInventario.Add(ajustePositivo);
        }

        if (detallesConDiferenciaNegativa.Count > 0)
        {
            if (string.IsNullOrWhiteSpace(registration.CodigoAjusteNegativo))
            {
                throw new InvalidOperationException("No se genero el correlativo para el ajuste negativo.");
            }

            ajusteNegativo = new AjusteInventarioWriteModel
            {
                Codigo = registration.CodigoAjusteNegativo,
                TipoAjuste = "NEGATIVO",
                FechaAjuste = registration.FechaCierre,
                Motivo = motivoBase,
                Observacion = observacionBase,
                UsuarioResponsableId = registration.UsuarioResponsableId
            };

            dbContext.AjustesInventario.Add(ajusteNegativo);
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        var affectedInsumoIds = new List<long>();

        foreach (var detail in details)
        {
            if (detail.StockContado == detail.StockSistema)
            {
                continue;
            }

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

            if (detail.StockContado > detail.StockSistema)
            {
                var cantidad = decimal.Round(detail.StockContado - detail.StockSistema, 4);
                var costoUnitario = stock.CostoPromedioActual > 0
                    ? stock.CostoPromedioActual
                    : insumo.CostoPromedioActual;

                var projection = inboundStockCalculator.Calculate(
                    stock.CantidadActual,
                    stock.CostoPromedioActual,
                    insumo.StockMinimo,
                    cantidad,
                    costoUnitario);

                stock.CantidadActual = projection.NuevoStock;
                stock.CostoPromedioActual = projection.NuevoCostoPromedio;
                stock.ActualizadoEn = registration.FechaCierre;

                insumo.CostoPromedioActual = projection.NuevoCostoPromedio;
                insumo.ActualizadoEn = registration.FechaCierre;
                insumo.ActualizadoPorUsuarioId = registration.UsuarioResponsableId;

                dbContext.AjustesInventarioDetalle.Add(new AjusteInventarioDetalleWriteModel
                {
                    AjusteInventarioId = ajustePositivo!.Id,
                    InsumoId = detail.InsumoId,
                    Cantidad = cantidad,
                    CostoUnitario = costoUnitario
                });

                dbContext.KardexMovimientos.Add(new KardexMovimientoWriteModel
                {
                    FechaMovimiento = registration.FechaCierre,
                    InsumoId = detail.InsumoId,
                    TipoMovimiento = "AJUSTE_POSITIVO",
                    DocumentoTipo = "AJUSTE_INVENTARIO",
                    DocumentoId = ajustePositivo.Id,
                    Entrada = cantidad,
                    Salida = 0,
                    StockActual = projection.NuevoStock,
                    EstadoStock = projection.EstadoStock,
                    CostoUnitario = costoUnitario,
                    CostoTotal = projection.CostoTotal,
                    UsuarioResponsableId = registration.UsuarioResponsableId,
                    Observacion = detail.Observacion ?? observacionBase ?? motivoBase
                });
            }
            else
            {
                var cantidad = decimal.Round(detail.StockSistema - detail.StockContado, 4);

                var projection = outboundStockCalculator.Calculate(
                    stock.CantidadActual,
                    stock.CostoPromedioActual,
                    insumo.StockMinimo,
                    cantidad);

                stock.CantidadActual = projection.NuevoStock;
                stock.ActualizadoEn = registration.FechaCierre;

                dbContext.AjustesInventarioDetalle.Add(new AjusteInventarioDetalleWriteModel
                {
                    AjusteInventarioId = ajusteNegativo!.Id,
                    InsumoId = detail.InsumoId,
                    Cantidad = cantidad,
                    CostoUnitario = projection.CostoUnitario
                });

                dbContext.KardexMovimientos.Add(new KardexMovimientoWriteModel
                {
                    FechaMovimiento = registration.FechaCierre,
                    InsumoId = detail.InsumoId,
                    TipoMovimiento = "AJUSTE_NEGATIVO",
                    DocumentoTipo = "AJUSTE_INVENTARIO",
                    DocumentoId = ajusteNegativo.Id,
                    Entrada = 0,
                    Salida = cantidad,
                    StockActual = projection.NuevoStock,
                    EstadoStock = projection.EstadoStock,
                    CostoUnitario = projection.CostoUnitario,
                    CostoTotal = projection.CostoTotal,
                    UsuarioResponsableId = registration.UsuarioResponsableId,
                    Observacion = detail.Observacion ?? observacionBase ?? motivoBase
                });
            }

            affectedInsumoIds.Add(detail.InsumoId);
        }

        inventarioFisico.Estado = "CERRADO";
        inventarioFisico.FechaCierre = registration.FechaCierre;
        inventarioFisico.Observacion = observacionBase ?? inventarioFisico.Observacion;

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        await TrySyncLowStockAlertsAsync(affectedInsumoIds, cancellationToken);
    }

    public async Task<InventarioFisico?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                i.id AS Id,
                i.codigo AS Codigo,
                i.fecha_inicio AS FechaInicio,
                i.fecha_cierre AS FechaCierre,
                i.periodo_anio AS PeriodoAnio,
                i.periodo_mes AS PeriodoMes,
                i.estado AS Estado,
                i.ejecutado_por_usuario_id AS EjecutadoPorUsuarioId,
                i.observacion AS Observacion,
                COUNT(d.id) AS TotalItems,
                ISNULL(SUM(CASE WHEN d.stock_contado <> d.stock_sistema THEN 1 ELSE 0 END), 0) AS ItemsConDiferencia,
                ISNULL(SUM(ABS(d.stock_contado - d.stock_sistema)), 0) AS TotalDiferenciaAbsoluta
            FROM inventario.inventario_fisico i
            LEFT JOIN inventario.inventario_fisico_detalle d ON d.inventario_fisico_id = i.id
            WHERE i.id = @Id
            GROUP BY
                i.id,
                i.codigo,
                i.fecha_inicio,
                i.fecha_cierre,
                i.periodo_anio,
                i.periodo_mes,
                i.estado,
                i.ejecutado_por_usuario_id,
                i.observacion;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<InventarioFisico>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<InventarioFisicoDetalle>> ListDetailsAsync(long inventarioFisicoId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.id AS Id,
                d.inventario_fisico_id AS InventarioFisicoId,
                d.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                d.stock_sistema AS StockSistema,
                d.stock_contado AS StockContado,
                d.diferencia AS Diferencia,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                d.observacion AS Observacion
            FROM inventario.inventario_fisico_detalle d
            INNER JOIN inventario.insumo i ON i.id = d.insumo_id
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            WHERE d.inventario_fisico_id = @InventarioFisicoId
            ORDER BY i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<InventarioFisicoDetalle>(
            new CommandDefinition(sql, new { InventarioFisicoId = inventarioFisicoId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<InventarioFisico>> ListAsync(InventarioFisicoFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                i.id AS Id,
                i.codigo AS Codigo,
                i.fecha_inicio AS FechaInicio,
                i.fecha_cierre AS FechaCierre,
                i.periodo_anio AS PeriodoAnio,
                i.periodo_mes AS PeriodoMes,
                i.estado AS Estado,
                i.ejecutado_por_usuario_id AS EjecutadoPorUsuarioId,
                i.observacion AS Observacion,
                COUNT(d.id) AS TotalItems,
                ISNULL(SUM(CASE WHEN d.stock_contado <> d.stock_sistema THEN 1 ELSE 0 END), 0) AS ItemsConDiferencia,
                ISNULL(SUM(ABS(d.stock_contado - d.stock_sistema)), 0) AS TotalDiferenciaAbsoluta
            FROM inventario.inventario_fisico i
            LEFT JOIN inventario.inventario_fisico_detalle d ON d.inventario_fisico_id = i.id
            WHERE (@PeriodoAnio IS NULL OR i.periodo_anio = @PeriodoAnio)
              AND (@PeriodoMes IS NULL OR i.periodo_mes = @PeriodoMes)
              AND (@Estado IS NULL OR i.estado = @Estado)
            GROUP BY
                i.id,
                i.codigo,
                i.fecha_inicio,
                i.fecha_cierre,
                i.periodo_anio,
                i.periodo_mes,
                i.estado,
                i.ejecutado_por_usuario_id,
                i.observacion
            ORDER BY i.fecha_inicio DESC, i.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<InventarioFisico>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.PeriodoAnio,
                    filters.PeriodoMes,
                    filters.Estado
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
            // Best-effort integration: el cierre ya fue confirmado y no debe revertirse por una alerta.
        }
    }
}
