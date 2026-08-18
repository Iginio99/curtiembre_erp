using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlFormulaConsumptionLookupRepository(ISqlConnectionFactory connectionFactory) : IFormulaConsumptionLookupRepository
{
    public async Task<IReadOnlyCollection<FormulaConsumptionDetail>> ListCurrentDetailsByProcessIdsAsync(
        IReadOnlyCollection<long> processIds,
        DateTime today,
        CancellationToken cancellationToken)
    {
        if (processIds.Count == 0)
        {
            return Array.Empty<FormulaConsumptionDetail>();
        }

        const string sql = """
            WITH current_versions AS (
                SELECT
                    f.proceso_productivo_id AS ProcesoProductivoId,
                    f.id AS FormulaId,
                    f.codigo AS FormulaCodigo,
                    fv.id AS FormulaVersionId,
                    fv.numero_version AS NumeroVersion,
                    ROW_NUMBER() OVER (
                        PARTITION BY f.proceso_productivo_id
                        ORDER BY
                            CASE WHEN fv.vigente = 1 THEN 0 ELSE 1 END,
                            fv.fecha_inicio_vigencia DESC,
                            fv.numero_version DESC,
                            fv.id DESC
                    ) AS RowNumber
                FROM configuracion.formula f
                INNER JOIN configuracion.formula_version fv ON fv.formula_id = f.id
                WHERE f.activo = 1
                  AND f.proceso_productivo_id IN @ProcessIds
                  AND fv.vigente = 1
                  AND fv.fecha_inicio_vigencia <= @Today
                  AND (fv.fecha_fin_vigencia IS NULL OR fv.fecha_fin_vigencia >= @Today)
            )
            SELECT
                cv.ProcesoProductivoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                cv.FormulaId,
                cv.FormulaCodigo,
                cv.FormulaVersionId,
                cv.NumeroVersion,
                fd.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                fd.porcentaje AS Porcentaje
            FROM current_versions cv
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = cv.ProcesoProductivoId
            INNER JOIN configuracion.formula_detalle fd ON fd.formula_version_id = cv.FormulaVersionId
            INNER JOIN inventario.insumo i ON i.id = fd.insumo_id
            WHERE cv.RowNumber = 1
              AND fd.activo = 1
            ORDER BY pp.orden_secuencia, fd.id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<FormulaConsumptionDetail>(
            new CommandDefinition(
                sql,
                new { ProcessIds = processIds.ToArray(), Today = today.Date },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
