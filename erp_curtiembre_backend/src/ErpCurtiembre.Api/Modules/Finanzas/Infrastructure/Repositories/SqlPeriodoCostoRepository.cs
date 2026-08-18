using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlPeriodoCostoRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : IPeriodoCostoRepository
{
    public Task<bool> ExistsByYearMonthAsync(int anio, int mes, long? excludeId, CancellationToken cancellationToken) =>
        dbContext.PeriodosCosto.AnyAsync(
            x => x.Anio == anio &&
                 x.Mes == mes &&
                 (!excludeId.HasValue || x.Id != excludeId.Value),
            cancellationToken);

    public async Task<PeriodoCosto?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                p.id AS Id,
                p.anio AS Anio,
                p.mes AS Mes,
                CAST(p.fecha_inicio AS datetime2) AS FechaInicio,
                CAST(p.fecha_fin AS datetime2) AS FechaFin,
                p.estado AS Estado,
                p.cerrado_en AS CerradoEn,
                p.cerrado_por_usuario_id AS CerradoPorUsuarioId,
                p.observacion AS Observacion,
                ISNULL(SUM(ci.monto), 0) AS TotalIndirectos
            FROM finanzas.periodo_costo p
            LEFT JOIN finanzas.costo_indirecto ci ON ci.periodo_costo_id = p.id
            WHERE p.id = @Id
            GROUP BY
                p.id,
                p.anio,
                p.mes,
                p.fecha_inicio,
                p.fecha_fin,
                p.estado,
                p.cerrado_en,
                p.cerrado_por_usuario_id,
                p.observacion;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<PeriodoCosto>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(PeriodoCosto periodoCosto, CancellationToken cancellationToken)
    {
        var entity = new PeriodoCostoWriteModel
        {
            Anio = periodoCosto.Anio,
            Mes = periodoCosto.Mes,
            FechaInicio = periodoCosto.FechaInicio.Date,
            FechaFin = periodoCosto.FechaFin.Date,
            Estado = periodoCosto.Estado,
            Observacion = periodoCosto.Observacion
        };

        dbContext.PeriodosCosto.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task CloseAsync(long id, DateTime closedAt, long actorId, string? observacion, CancellationToken cancellationToken)
    {
        var entity = await dbContext.PeriodosCosto.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Estado = "CERRADO";
        entity.CerradoEn = closedAt;
        entity.CerradoPorUsuarioId = actorId;
        entity.Observacion = observacion;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<PeriodoCosto>> ListAsync(PeriodoCostoFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                p.id AS Id,
                p.anio AS Anio,
                p.mes AS Mes,
                CAST(p.fecha_inicio AS datetime2) AS FechaInicio,
                CAST(p.fecha_fin AS datetime2) AS FechaFin,
                p.estado AS Estado,
                p.cerrado_en AS CerradoEn,
                p.cerrado_por_usuario_id AS CerradoPorUsuarioId,
                p.observacion AS Observacion,
                ISNULL(SUM(ci.monto), 0) AS TotalIndirectos
            FROM finanzas.periodo_costo p
            LEFT JOIN finanzas.costo_indirecto ci ON ci.periodo_costo_id = p.id
            WHERE (@Anio IS NULL OR p.anio = @Anio)
              AND (@Mes IS NULL OR p.mes = @Mes)
              AND (@Estado IS NULL OR p.estado = @Estado)
            GROUP BY
                p.id,
                p.anio,
                p.mes,
                p.fecha_inicio,
                p.fecha_fin,
                p.estado,
                p.cerrado_en,
                p.cerrado_por_usuario_id,
                p.observacion
            ORDER BY p.anio DESC, p.mes DESC, p.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<PeriodoCosto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Anio,
                    filters.Mes,
                    filters.Estado
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
