using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlCostoOrdenRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : ICostoOrdenRepository
{
    public async Task<CostoOrden?> FindByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                co.id AS Id,
                co.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                co.periodo_costo_id AS PeriodoCostoId,
                p.anio AS PeriodoAnio,
                p.mes AS PeriodoMes,
                co.costo_pieles AS CostoPieles,
                co.costo_insumos AS CostoInsumos,
                co.costo_mano_obra AS CostoManoObra,
                co.costo_indirecto_asignado AS CostoIndirectoAsignado,
                co.costo_depreciacion_asignado AS CostoDepreciacionAsignado,
                co.costo_total AS CostoTotal,
                co.pieles_buenas_finales AS PielesBuenasFinales,
                co.costo_por_piel AS CostoPorPiel,
                co.costo_estimado AS CostoEstimado,
                co.costo_real AS CostoReal,
                co.estado AS Estado,
                co.calculado_en AS CalculadoEn,
                co.calculado_por_usuario_id AS CalculadoPorUsuarioId
            FROM finanzas.costo_orden co
            INNER JOIN produccion.orden_produccion op ON op.id = co.orden_produccion_id
            LEFT JOIN finanzas.periodo_costo p ON p.id = co.periodo_costo_id
            WHERE co.orden_produccion_id = @OrdenProduccionId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<CostoOrden>(
            new CommandDefinition(sql, new { OrdenProduccionId = ordenProduccionId }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<CostoOrden>> ListAsync(CostoOrdenFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                co.id AS Id,
                co.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                co.periodo_costo_id AS PeriodoCostoId,
                p.anio AS PeriodoAnio,
                p.mes AS PeriodoMes,
                co.costo_pieles AS CostoPieles,
                co.costo_insumos AS CostoInsumos,
                co.costo_mano_obra AS CostoManoObra,
                co.costo_indirecto_asignado AS CostoIndirectoAsignado,
                co.costo_depreciacion_asignado AS CostoDepreciacionAsignado,
                co.costo_total AS CostoTotal,
                co.pieles_buenas_finales AS PielesBuenasFinales,
                co.costo_por_piel AS CostoPorPiel,
                co.costo_estimado AS CostoEstimado,
                co.costo_real AS CostoReal,
                co.estado AS Estado,
                co.calculado_en AS CalculadoEn,
                co.calculado_por_usuario_id AS CalculadoPorUsuarioId
            FROM finanzas.costo_orden co
            INNER JOIN produccion.orden_produccion op ON op.id = co.orden_produccion_id
            LEFT JOIN finanzas.periodo_costo p ON p.id = co.periodo_costo_id
            WHERE (@OrdenProduccionId IS NULL OR co.orden_produccion_id = @OrdenProduccionId)
              AND (@PeriodoCostoId IS NULL OR co.periodo_costo_id = @PeriodoCostoId)
              AND (@Estado IS NULL OR co.estado = @Estado)
            ORDER BY co.calculado_en DESC, co.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<CostoOrden>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.OrdenProduccionId,
                    filters.PeriodoCostoId,
                    filters.Estado
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task UpsertAsync(CostoOrden costoOrden, CancellationToken cancellationToken)
    {
        var existing = await dbContext.CostosOrden
            .SingleOrDefaultAsync(x => x.OrdenProduccionId == costoOrden.OrdenProduccionId, cancellationToken);

        if (existing is null)
        {
            dbContext.CostosOrden.Add(new CostoOrdenWriteModel
            {
                OrdenProduccionId = costoOrden.OrdenProduccionId,
                PeriodoCostoId = costoOrden.PeriodoCostoId,
                CostoPieles = costoOrden.CostoPieles,
                CostoInsumos = costoOrden.CostoInsumos,
                CostoManoObra = costoOrden.CostoManoObra,
                CostoIndirectoAsignado = costoOrden.CostoIndirectoAsignado,
                CostoDepreciacionAsignado = costoOrden.CostoDepreciacionAsignado,
                PielesBuenasFinales = costoOrden.PielesBuenasFinales,
                CostoPorPiel = costoOrden.CostoPorPiel,
                CostoEstimado = costoOrden.CostoEstimado,
                CostoReal = costoOrden.CostoReal,
                Estado = costoOrden.Estado,
                CalculadoEn = costoOrden.CalculadoEn,
                CalculadoPorUsuarioId = costoOrden.CalculadoPorUsuarioId
            });
        }
        else
        {
            existing.PeriodoCostoId = costoOrden.PeriodoCostoId;
            existing.CostoPieles = costoOrden.CostoPieles;
            existing.CostoInsumos = costoOrden.CostoInsumos;
            existing.CostoManoObra = costoOrden.CostoManoObra;
            existing.CostoIndirectoAsignado = costoOrden.CostoIndirectoAsignado;
            existing.CostoDepreciacionAsignado = costoOrden.CostoDepreciacionAsignado;
            existing.PielesBuenasFinales = costoOrden.PielesBuenasFinales;
            existing.CostoPorPiel = costoOrden.CostoPorPiel;
            existing.CostoEstimado = costoOrden.CostoEstimado;
            existing.CostoReal = costoOrden.CostoReal;
            existing.Estado = costoOrden.Estado;
            existing.CalculadoEn = costoOrden.CalculadoEn;
            existing.CalculadoPorUsuarioId = costoOrden.CalculadoPorUsuarioId;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
