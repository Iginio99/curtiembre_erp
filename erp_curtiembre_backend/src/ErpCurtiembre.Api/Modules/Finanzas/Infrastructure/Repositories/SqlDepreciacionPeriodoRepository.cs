using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlDepreciacionPeriodoRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : IDepreciacionPeriodoRepository
{
    public async Task<DepreciacionPeriodo?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                d.id AS Id,
                d.periodo_costo_id AS PeriodoCostoId,
                p.anio AS PeriodoAnio,
                p.mes AS PeriodoMes,
                d.activo_depreciable_id AS ActivoDepreciableId,
                a.codigo AS ActivoCodigo,
                a.nombre AS ActivoNombre,
                d.monto_depreciacion AS MontoDepreciacion,
                d.calculado_en AS CalculadoEn
            FROM finanzas.depreciacion_periodo d
            INNER JOIN finanzas.periodo_costo p ON p.id = d.periodo_costo_id
            INNER JOIN finanzas.activo_depreciable a ON a.id = d.activo_depreciable_id
            WHERE d.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<DepreciacionPeriodo>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<DepreciacionPeriodo>> ListAsync(DepreciacionPeriodoFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.id AS Id,
                d.periodo_costo_id AS PeriodoCostoId,
                p.anio AS PeriodoAnio,
                p.mes AS PeriodoMes,
                d.activo_depreciable_id AS ActivoDepreciableId,
                a.codigo AS ActivoCodigo,
                a.nombre AS ActivoNombre,
                d.monto_depreciacion AS MontoDepreciacion,
                d.calculado_en AS CalculadoEn
            FROM finanzas.depreciacion_periodo d
            INNER JOIN finanzas.periodo_costo p ON p.id = d.periodo_costo_id
            INNER JOIN finanzas.activo_depreciable a ON a.id = d.activo_depreciable_id
            WHERE (@PeriodoCostoId IS NULL OR d.periodo_costo_id = @PeriodoCostoId)
              AND (@ActivoDepreciableId IS NULL OR d.activo_depreciable_id = @ActivoDepreciableId)
            ORDER BY p.anio DESC, p.mes DESC, a.codigo, d.id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<DepreciacionPeriodo>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.PeriodoCostoId,
                    filters.ActivoDepreciableId
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<long>> ListRegisteredAssetIdsByPeriodAsync(long periodoCostoId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT d.activo_depreciable_id
            FROM finanzas.depreciacion_periodo d
            WHERE d.periodo_costo_id = @PeriodoCostoId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var ids = await connection.QueryAsync<long>(
            new CommandDefinition(sql, new { PeriodoCostoId = periodoCostoId }, cancellationToken: cancellationToken));

        return ids.ToArray();
    }

    public async Task CreateManyAsync(IReadOnlyCollection<DepreciacionPeriodo> depreciaciones, CancellationToken cancellationToken)
    {
        if (depreciaciones.Count == 0)
        {
            return;
        }

        foreach (var item in depreciaciones)
        {
            dbContext.DepreciacionesPeriodo.Add(new DepreciacionPeriodoWriteModel
            {
                PeriodoCostoId = item.PeriodoCostoId,
                ActivoDepreciableId = item.ActivoDepreciableId,
                MontoDepreciacion = item.MontoDepreciacion,
                CalculadoEn = item.CalculadoEn
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
