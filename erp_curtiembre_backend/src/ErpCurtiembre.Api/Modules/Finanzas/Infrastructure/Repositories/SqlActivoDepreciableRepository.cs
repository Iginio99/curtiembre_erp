using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlActivoDepreciableRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : IActivoDepreciableRepository
{
    public Task<bool> ExistsByCodigoAsync(string codigo, long? excludeId, CancellationToken cancellationToken) =>
        dbContext.ActivosDepreciables.AnyAsync(
            x => x.Codigo == codigo &&
                 (!excludeId.HasValue || x.Id != excludeId.Value),
            cancellationToken);

    public async Task<ActivoDepreciable?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                a.id AS Id,
                a.codigo AS Codigo,
                a.nombre AS Nombre,
                a.valor_compra AS ValorCompra,
                CAST(a.fecha_compra AS datetime2) AS FechaCompra,
                a.vida_util_meses AS VidaUtilMeses,
                a.valor_residual AS ValorResidual,
                a.activo AS Activo,
                a.creado_en AS CreadoEn
            FROM finanzas.activo_depreciable a
            WHERE a.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ActivoDepreciable>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(ActivoDepreciable activo, CancellationToken cancellationToken)
    {
        var entity = new ActivoDepreciableWriteModel
        {
            Codigo = activo.Codigo,
            Nombre = activo.Nombre,
            ValorCompra = activo.ValorCompra,
            FechaCompra = activo.FechaCompra.Date,
            VidaUtilMeses = activo.VidaUtilMeses,
            ValorResidual = activo.ValorResidual,
            Activo = activo.Activo
        };

        dbContext.ActivosDepreciables.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(ActivoDepreciable activo, CancellationToken cancellationToken)
    {
        var entity = await dbContext.ActivosDepreciables.SingleOrDefaultAsync(x => x.Id == activo.Id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Codigo = activo.Codigo;
        entity.Nombre = activo.Nombre;
        entity.ValorCompra = activo.ValorCompra;
        entity.FechaCompra = activo.FechaCompra.Date;
        entity.VidaUtilMeses = activo.VidaUtilMeses;
        entity.ValorResidual = activo.ValorResidual;
        entity.Activo = activo.Activo;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<ActivoDepreciable>> ListAsync(ActivoDepreciableFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                a.id AS Id,
                a.codigo AS Codigo,
                a.nombre AS Nombre,
                a.valor_compra AS ValorCompra,
                CAST(a.fecha_compra AS datetime2) AS FechaCompra,
                a.vida_util_meses AS VidaUtilMeses,
                a.valor_residual AS ValorResidual,
                a.activo AS Activo,
                a.creado_en AS CreadoEn
            FROM finanzas.activo_depreciable a
            WHERE (
                    @Texto IS NULL OR
                    a.codigo LIKE @TextoLike OR
                    a.nombre LIKE @TextoLike
                  )
              AND (@Activo IS NULL OR a.activo = @Activo)
            ORDER BY a.codigo, a.id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ActivoDepreciable>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.Activo
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<ActivoDepreciable>> ListEligibleForPeriodAsync(DateTime fechaFinPeriodo, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                a.id AS Id,
                a.codigo AS Codigo,
                a.nombre AS Nombre,
                a.valor_compra AS ValorCompra,
                CAST(a.fecha_compra AS datetime2) AS FechaCompra,
                a.vida_util_meses AS VidaUtilMeses,
                a.valor_residual AS ValorResidual,
                a.activo AS Activo,
                a.creado_en AS CreadoEn
            FROM finanzas.activo_depreciable a
            WHERE a.activo = 1
              AND a.fecha_compra <= @FechaFinPeriodo
            ORDER BY a.codigo, a.id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ActivoDepreciable>(
            new CommandDefinition(sql, new { FechaFinPeriodo = fechaFinPeriodo.Date }, cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
