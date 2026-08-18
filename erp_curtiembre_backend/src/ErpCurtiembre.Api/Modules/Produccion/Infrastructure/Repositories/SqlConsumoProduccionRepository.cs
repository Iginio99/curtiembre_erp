using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlConsumoProduccionRepository(
    ISqlConnectionFactory connectionFactory,
    ProduccionDbContext dbContext) : IConsumoProduccionRepository
{
    public Task<bool> HasPlannedConsumptionAsync(long orderId, CancellationToken cancellationToken) =>
        dbContext.OrdenesConsumoPlanificado.AnyAsync(x => x.OrdenProduccionId == orderId, cancellationToken);

    public async Task RegisterPlannedConsumptionAsync(
        IReadOnlyCollection<OrdenConsumoPlanificado> items,
        CancellationToken cancellationToken)
    {
        if (items.Count == 0)
        {
            return;
        }

        foreach (var item in items)
        {
            dbContext.OrdenesConsumoPlanificado.Add(new OrdenConsumoPlanificadoWriteModel
            {
                OrdenProduccionId = item.OrdenProduccionId,
                OrdenProcesoId = item.OrdenProcesoId,
                FormulaVersionId = item.FormulaVersionId,
                InsumoId = item.InsumoId,
                Porcentaje = item.Porcentaje,
                CantidadPlanificada = item.CantidadPlanificada
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<OrdenConsumoPlanificado>> ListPlannedAsync(
        long orderId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                p.id AS Id,
                p.orden_produccion_id AS OrdenProduccionId,
                p.orden_proceso_id AS OrdenProcesoId,
                opp.proceso_productivo_id AS ProcesoProductivoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                p.formula_version_id AS FormulaVersionId,
                p.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                p.porcentaje AS Porcentaje,
                p.cantidad_planificada AS CantidadPlanificada,
                p.creado_en AS CreadoEn
            FROM produccion.orden_consumo_planificado p
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = p.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            INNER JOIN inventario.insumo i ON i.id = p.insumo_id
            WHERE p.orden_produccion_id = @OrderId
            ORDER BY opp.secuencia, i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<OrdenConsumoPlanificado>(
            new CommandDefinition(sql, new { OrderId = orderId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task RegisterRealConsumptionAsync(
        IReadOnlyCollection<OrdenConsumoReal> realItems,
        IReadOnlyCollection<DesviacionConsumo> desviaciones,
        CancellationToken cancellationToken)
    {
        if (realItems.Count == 0)
        {
            return;
        }

        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var realEntities = new List<OrdenConsumoRealWriteModel>();
        foreach (var item in realItems)
        {
            var entity = new OrdenConsumoRealWriteModel
            {
                OrdenProduccionId = item.OrdenProduccionId,
                OrdenProcesoId = item.OrdenProcesoId,
                SalidaInventarioDetalleId = item.SalidaInventarioDetalleId,
                InsumoId = item.InsumoId,
                CantidadConsumida = item.CantidadConsumida,
                CostoUnitario = item.CostoUnitario,
                EsExtra = item.EsExtra
            };

            realEntities.Add(entity);
            dbContext.OrdenesConsumoReal.Add(entity);
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        var deviationList = desviaciones.ToList();
        for (var index = 0; index < deviationList.Count; index++)
        {
            var deviation = deviationList[index];
            var realEntity = realEntities[index];

            dbContext.DesviacionesConsumo.Add(new DesviacionConsumoWriteModel
            {
                OrdenConsumoPlanificadoId = deviation.OrdenConsumoPlanificadoId,
                OrdenConsumoRealId = realEntity.Id,
                CantidadPlanificada = deviation.CantidadPlanificada,
                CantidadReal = deviation.CantidadReal,
                Motivo = deviation.Motivo
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<OrdenConsumoReal>> ListRealAsync(
        long orderId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                r.id AS Id,
                r.orden_produccion_id AS OrdenProduccionId,
                r.orden_proceso_id AS OrdenProcesoId,
                opp.proceso_productivo_id AS ProcesoProductivoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                r.salida_inventario_detalle_id AS SalidaInventarioDetalleId,
                r.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                r.cantidad_consumida AS CantidadConsumida,
                r.costo_unitario AS CostoUnitario,
                r.costo_total AS CostoTotal,
                r.es_extra AS EsExtra,
                r.creado_en AS CreadoEn
            FROM produccion.orden_consumo_real r
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = r.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            INNER JOIN inventario.insumo i ON i.id = r.insumo_id
            WHERE r.orden_produccion_id = @OrderId
            ORDER BY r.creado_en, r.id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<OrdenConsumoReal>(
            new CommandDefinition(sql, new { OrderId = orderId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<DesviacionConsumo>> ListDeviationsAsync(
        long orderId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.id AS Id,
                d.orden_consumo_planificado_id AS OrdenConsumoPlanificadoId,
                d.orden_consumo_real_id AS OrdenConsumoRealId,
                r.orden_produccion_id AS OrdenProduccionId,
                r.orden_proceso_id AS OrdenProcesoId,
                opp.proceso_productivo_id AS ProcesoProductivoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                r.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                d.cantidad_planificada AS CantidadPlanificada,
                d.cantidad_real AS CantidadReal,
                d.cantidad_desviacion AS CantidadDesviacion,
                d.motivo AS Motivo,
                d.registrado_en AS RegistradoEn
            FROM produccion.desviacion_consumo d
            INNER JOIN produccion.orden_consumo_real r ON r.id = d.orden_consumo_real_id
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = r.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            INNER JOIN inventario.insumo i ON i.id = r.insumo_id
            WHERE r.orden_produccion_id = @OrderId
            ORDER BY d.registrado_en DESC, d.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<DesviacionConsumo>(
            new CommandDefinition(sql, new { OrderId = orderId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ConsumoRealAcumulado>> ListAccumulatedRealByProcessAsync(
        long orderId,
        long processId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                r.insumo_id AS InsumoId,
                SUM(r.cantidad_consumida) AS CantidadConsumida
            FROM produccion.orden_consumo_real r
            WHERE r.orden_produccion_id = @OrderId
              AND r.orden_proceso_id = @ProcessId
            GROUP BY r.insumo_id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ConsumoRealAcumulado>(
            new CommandDefinition(
                sql,
                new { OrderId = orderId, ProcessId = processId },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
