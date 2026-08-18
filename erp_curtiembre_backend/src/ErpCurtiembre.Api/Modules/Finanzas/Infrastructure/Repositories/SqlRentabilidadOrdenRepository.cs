using Dapper;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Repositories;

public sealed class SqlRentabilidadOrdenRepository(
    ISqlConnectionFactory connectionFactory,
    FinanzasDbContext dbContext) : IRentabilidadOrdenRepository
{
    public async Task<RentabilidadOrden?> FindByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                r.id AS Id,
                r.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenProduccionCodigo,
                r.precio_venta AS PrecioVenta,
                r.costo_total AS CostoTotal,
                r.utilidad AS Utilidad,
                r.margen_porcentaje AS MargenPorcentaje,
                r.calculado_en AS CalculadoEn
            FROM finanzas.rentabilidad_orden r
            INNER JOIN produccion.orden_produccion op ON op.id = r.orden_produccion_id
            WHERE r.orden_produccion_id = @OrdenProduccionId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<RentabilidadOrden>(
            new CommandDefinition(sql, new { OrdenProduccionId = ordenProduccionId }, cancellationToken: cancellationToken));
    }

    public async Task UpsertAsync(RentabilidadOrden rentabilidadOrden, CancellationToken cancellationToken)
    {
        var existing = await dbContext.RentabilidadesOrden
            .SingleOrDefaultAsync(x => x.OrdenProduccionId == rentabilidadOrden.OrdenProduccionId, cancellationToken);

        if (existing is null)
        {
            dbContext.RentabilidadesOrden.Add(new RentabilidadOrdenWriteModel
            {
                OrdenProduccionId = rentabilidadOrden.OrdenProduccionId,
                PrecioVenta = rentabilidadOrden.PrecioVenta,
                CostoTotal = rentabilidadOrden.CostoTotal,
                MargenPorcentaje = rentabilidadOrden.MargenPorcentaje,
                CalculadoEn = rentabilidadOrden.CalculadoEn
            });
        }
        else
        {
            existing.PrecioVenta = rentabilidadOrden.PrecioVenta;
            existing.CostoTotal = rentabilidadOrden.CostoTotal;
            existing.MargenPorcentaje = rentabilidadOrden.MargenPorcentaje;
            existing.CalculadoEn = rentabilidadOrden.CalculadoEn;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
