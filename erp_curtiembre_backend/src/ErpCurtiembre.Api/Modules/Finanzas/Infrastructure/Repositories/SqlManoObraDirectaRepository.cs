using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlManoObraDirectaRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : IManoObraDirectaRepository
{
    public async Task<ManoObraDirecta?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                mo.id AS Id,
                mo.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                mo.orden_proceso_id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                mo.monto AS Monto,
                mo.descripcion AS Descripcion,
                mo.registrado_en AS RegistradoEn,
                mo.registrado_por_usuario_id AS RegistradoPorUsuarioId
            FROM finanzas.mano_obra_directa mo
            INNER JOIN produccion.orden_produccion op ON op.id = mo.orden_produccion_id
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = mo.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            WHERE mo.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ManoObraDirecta>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(ManoObraDirecta manoObraDirecta, CancellationToken cancellationToken)
    {
        var entity = new ManoObraDirectaWriteModel
        {
            OrdenProduccionId = manoObraDirecta.OrdenProduccionId,
            OrdenProcesoId = manoObraDirecta.OrdenProcesoId,
            Monto = manoObraDirecta.Monto,
            Descripcion = manoObraDirecta.Descripcion,
            RegistradoEn = manoObraDirecta.RegistradoEn,
            RegistradoPorUsuarioId = manoObraDirecta.RegistradoPorUsuarioId
        };

        dbContext.ManosObraDirecta.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task<IReadOnlyCollection<ManoObraDirecta>> ListAsync(ManoObraDirectaFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                mo.id AS Id,
                mo.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                mo.orden_proceso_id AS OrdenProcesoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                mo.monto AS Monto,
                mo.descripcion AS Descripcion,
                mo.registrado_en AS RegistradoEn,
                mo.registrado_por_usuario_id AS RegistradoPorUsuarioId
            FROM finanzas.mano_obra_directa mo
            INNER JOIN produccion.orden_produccion op ON op.id = mo.orden_produccion_id
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = mo.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            WHERE (@OrdenProduccionId IS NULL OR mo.orden_produccion_id = @OrdenProduccionId)
              AND (@OrdenProcesoId IS NULL OR mo.orden_proceso_id = @OrdenProcesoId)
            ORDER BY mo.registrado_en DESC, mo.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ManoObraDirecta>(
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
}
