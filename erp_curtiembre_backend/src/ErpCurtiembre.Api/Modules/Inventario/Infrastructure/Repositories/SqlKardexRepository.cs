using Dapper;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;

public sealed class SqlKardexRepository(ISqlConnectionFactory connectionFactory) : IKardexRepository
{
    public async Task<IReadOnlyCollection<KardexMovimiento>> ListAsync(KardexFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                k.id AS Id,
                k.fecha_movimiento AS FechaMovimiento,
                k.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                k.tipo_movimiento AS TipoMovimiento,
                k.documento_tipo AS DocumentoTipo,
                k.documento_id AS DocumentoId,
                k.entrada AS Entrada,
                k.salida AS Salida,
                k.stock_actual AS StockActual,
                k.estado_stock AS EstadoStock,
                k.costo_unitario AS CostoUnitario,
                k.costo_total AS CostoTotal,
                k.usuario_responsable_id AS UsuarioResponsableId,
                CASE
                    WHEN u.id IS NULL THEN NULL
                    ELSE CONCAT(u.nombres, ' ', u.apellidos)
                END AS UsuarioResponsable,
                k.observacion AS Observacion
            FROM inventario.kardex_movimiento k
            INNER JOIN inventario.insumo i ON i.id = k.insumo_id
            LEFT JOIN seguridad.usuario u ON u.id = k.usuario_responsable_id
            WHERE (@InsumoId IS NULL OR k.insumo_id = @InsumoId)
              AND (@TipoMovimiento IS NULL OR k.tipo_movimiento = @TipoMovimiento)
              AND (@DocumentoTipo IS NULL OR k.documento_tipo = @DocumentoTipo)
              AND (@UsuarioResponsableId IS NULL OR k.usuario_responsable_id = @UsuarioResponsableId)
              AND (@FechaDesde IS NULL OR k.fecha_movimiento >= @FechaDesde)
              AND (@FechaHasta IS NULL OR k.fecha_movimiento <= @FechaHasta)
            ORDER BY k.fecha_movimiento DESC, k.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<KardexMovimiento>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.InsumoId,
                    filters.TipoMovimiento,
                    filters.DocumentoTipo,
                    filters.UsuarioResponsableId,
                    filters.FechaDesde,
                    filters.FechaHasta
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public Task<IReadOnlyCollection<KardexMovimiento>> ListByInsumoAsync(long insumoId, KardexFiltersDto filters, CancellationToken cancellationToken) =>
        ListAsync(filters with { InsumoId = insumoId }, cancellationToken);
}
