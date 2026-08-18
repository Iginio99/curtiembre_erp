using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlCostoProcesoRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : ICostoProcesoRepository
{
    public async Task<CostoProceso?> FindByOrderProcessIdAsync(long ordenProcesoId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                cp.id AS Id,
                cp.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                cp.orden_proceso_id AS OrdenProcesoId,
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
            WHERE cp.orden_proceso_id = @OrdenProcesoId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<CostoProceso>(
            new CommandDefinition(sql, new { OrdenProcesoId = ordenProcesoId }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<CostoProceso>> ListAsync(CostoProcesoFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                cp.id AS Id,
                cp.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                cp.orden_proceso_id AS OrdenProcesoId,
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
            WHERE (@OrdenProduccionId IS NULL OR cp.orden_produccion_id = @OrdenProduccionId)
              AND (@OrdenProcesoId IS NULL OR cp.orden_proceso_id = @OrdenProcesoId)
            ORDER BY cp.calculado_en DESC, cp.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<CostoProceso>(
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

    public async Task UpsertAsync(CostoProceso costoProceso, CancellationToken cancellationToken)
    {
        var existing = await dbContext.CostosProceso
            .SingleOrDefaultAsync(x => x.OrdenProcesoId == costoProceso.OrdenProcesoId, cancellationToken);

        if (existing is null)
        {
            dbContext.CostosProceso.Add(new CostoProcesoWriteModel
            {
                OrdenProduccionId = costoProceso.OrdenProduccionId,
                OrdenProcesoId = costoProceso.OrdenProcesoId,
                CostoInsumos = costoProceso.CostoInsumos,
                CostoManoObra = costoProceso.CostoManoObra,
                CalculadoEn = costoProceso.CalculadoEn
            });
        }
        else
        {
            existing.OrdenProduccionId = costoProceso.OrdenProduccionId;
            existing.CostoInsumos = costoProceso.CostoInsumos;
            existing.CostoManoObra = costoProceso.CostoManoObra;
            existing.CalculadoEn = costoProceso.CalculadoEn;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
