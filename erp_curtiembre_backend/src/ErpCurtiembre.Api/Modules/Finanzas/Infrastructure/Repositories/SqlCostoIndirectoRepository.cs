using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlCostoIndirectoRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : ICostoIndirectoRepository
{
    public async Task<CostoIndirecto?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                ci.id AS Id,
                ci.periodo_costo_id AS PeriodoCostoId,
                p.anio AS PeriodoAnio,
                p.mes AS PeriodoMes,
                p.estado AS PeriodoEstado,
                ci.tipo_costo AS TipoCosto,
                ci.descripcion AS Descripcion,
                ci.monto AS Monto,
                ci.registrado_en AS RegistradoEn,
                ci.registrado_por_usuario_id AS RegistradoPorUsuarioId
            FROM finanzas.costo_indirecto ci
            INNER JOIN finanzas.periodo_costo p ON p.id = ci.periodo_costo_id
            WHERE ci.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<CostoIndirecto>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(CostoIndirecto costoIndirecto, CancellationToken cancellationToken)
    {
        var entity = new CostoIndirectoWriteModel
        {
            PeriodoCostoId = costoIndirecto.PeriodoCostoId,
            TipoCosto = costoIndirecto.TipoCosto,
            Descripcion = costoIndirecto.Descripcion,
            Monto = costoIndirecto.Monto,
            RegistradoEn = costoIndirecto.RegistradoEn,
            RegistradoPorUsuarioId = costoIndirecto.RegistradoPorUsuarioId
        };

        dbContext.CostosIndirectos.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task<IReadOnlyCollection<CostoIndirecto>> ListAsync(CostoIndirectoFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                ci.id AS Id,
                ci.periodo_costo_id AS PeriodoCostoId,
                p.anio AS PeriodoAnio,
                p.mes AS PeriodoMes,
                p.estado AS PeriodoEstado,
                ci.tipo_costo AS TipoCosto,
                ci.descripcion AS Descripcion,
                ci.monto AS Monto,
                ci.registrado_en AS RegistradoEn,
                ci.registrado_por_usuario_id AS RegistradoPorUsuarioId
            FROM finanzas.costo_indirecto ci
            INNER JOIN finanzas.periodo_costo p ON p.id = ci.periodo_costo_id
            WHERE (@PeriodoCostoId IS NULL OR ci.periodo_costo_id = @PeriodoCostoId)
              AND (@TipoCosto IS NULL OR ci.tipo_costo = @TipoCosto)
              AND (
                    @Texto IS NULL OR
                    ci.tipo_costo LIKE @TextoLike OR
                    ci.descripcion LIKE @TextoLike
                  )
            ORDER BY ci.registrado_en DESC, ci.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<CostoIndirecto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.PeriodoCostoId,
                    filters.TipoCosto,
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%"
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
