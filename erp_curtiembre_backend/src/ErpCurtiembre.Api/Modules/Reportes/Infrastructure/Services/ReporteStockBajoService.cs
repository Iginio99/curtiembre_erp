using Dapper;
using ErpCurtiembre.Modules.Reportes.Application.DTOs;
using ErpCurtiembre.Modules.Reportes.Application.Ports;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Reportes.Infrastructure.Services;

public sealed class ReporteStockBajoService(ISqlConnectionFactory connectionFactory) : IReporteStockBajoService
{
    public async Task<IReadOnlyCollection<StockBajoReporteDto>> GetLowStockAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                insumo_id AS InsumoId,
                codigo_insumo AS CodigoInsumo,
                insumo AS Insumo,
                cantidad_actual AS CantidadActual,
                stock_minimo AS StockMinimo,
                estado_stock AS EstadoStock,
                costo_promedio_actual AS CostoPromedioActual,
                actualizado_en AS ActualizadoEn
            FROM reportes.vw_stock_bajo
            ORDER BY cantidad_actual ASC, codigo_insumo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<StockBajoReporteDto>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
