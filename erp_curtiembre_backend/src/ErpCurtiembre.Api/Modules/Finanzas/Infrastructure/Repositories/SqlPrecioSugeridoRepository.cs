using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlPrecioSugeridoRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : IPrecioSugeridoRepository
{
    public async Task<PrecioSugerido?> FindByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                p.id AS Id,
                p.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                p.costo_base_sin_igv AS CostoBaseSinIgv,
                p.margen_porcentaje AS MargenPorcentaje,
                p.precio_sugerido_sin_igv AS PrecioSugeridoSinIgv,
                p.igv_porcentaje AS IgvPorcentaje,
                p.precio_sugerido_con_igv AS PrecioSugeridoConIgv,
                p.calculado_en AS CalculadoEn
            FROM finanzas.precio_sugerido p
            INNER JOIN produccion.orden_produccion op ON op.id = p.orden_produccion_id
            WHERE p.orden_produccion_id = @OrdenProduccionId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<PrecioSugerido>(
            new CommandDefinition(sql, new { OrdenProduccionId = ordenProduccionId }, cancellationToken: cancellationToken));
    }

    public async Task UpsertAsync(PrecioSugerido precioSugerido, CancellationToken cancellationToken)
    {
        var existing = await dbContext.PreciosSugeridos
            .SingleOrDefaultAsync(x => x.OrdenProduccionId == precioSugerido.OrdenProduccionId, cancellationToken);

        if (existing is null)
        {
            dbContext.PreciosSugeridos.Add(new PrecioSugeridoWriteModel
            {
                OrdenProduccionId = precioSugerido.OrdenProduccionId,
                CostoBaseSinIgv = precioSugerido.CostoBaseSinIgv,
                MargenPorcentaje = precioSugerido.MargenPorcentaje,
                IgvPorcentaje = precioSugerido.IgvPorcentaje,
                CalculadoEn = precioSugerido.CalculadoEn
            });
        }
        else
        {
            existing.CostoBaseSinIgv = precioSugerido.CostoBaseSinIgv;
            existing.MargenPorcentaje = precioSugerido.MargenPorcentaje;
            existing.IgvPorcentaje = precioSugerido.IgvPorcentaje;
            existing.CalculadoEn = precioSugerido.CalculadoEn;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
