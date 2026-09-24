using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlLoteRepository(
    ISqlConnectionFactory connectionFactory,
    ProduccionDbContext dbContext) : ILoteRepository
{
    public async Task<Lote?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                l.id AS Id,
                l.codigo AS Codigo,
                l.cliente_id AS ClienteId,
                c.razon_social AS ClienteRazonSocial,
                l.tipo_piel_id AS TipoPielId,
                tp.codigo AS TipoPielCodigo,
                tp.nombre AS TipoPielNombre,
                l.fecha_ingreso AS FechaIngreso,
                l.cantidad_pieles_inicial AS CantidadPielesInicial,
                CONVERT(DECIMAL(18,4), l.cantidad_pieles_inicial - l.cantidad_pieles_disponible) AS CantidadPielesUtilizada,
                l.cantidad_pieles_disponible AS CantidadPielesDisponible,
                CAST(l.cantidad_pieles_inicial * 2.0 AS DECIMAL(18,2)) AS CantidadLadosCalculada,
                l.cliente_trae_lote AS ClienteTraeLote,
                l.costo_pieles_total AS CostoPielesTotal,
                l.observacion AS Observacion,
                l.estado AS Estado,
                l.creado_en AS CreadoEn,
                l.creado_por_usuario_id AS CreadoPorUsuarioId
            FROM produccion.lote l
            INNER JOIN produccion.cliente c ON c.id = l.cliente_id
            INNER JOIN configuracion.tipo_piel tp ON tp.id = l.tipo_piel_id
            WHERE l.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Lote>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> CreateAsync(Lote lote, CancellationToken cancellationToken)
    {
        var entity = new LoteWriteModel
        {
            Codigo = lote.Codigo,
            ClienteId = lote.ClienteId,
            TipoPielId = lote.TipoPielId,
            FechaIngreso = lote.FechaIngreso,
            CantidadPielesInicial = lote.CantidadPielesInicial,
            CantidadPielesDisponible = lote.CantidadPielesDisponible,
            ClienteTraeLote = lote.ClienteTraeLote,
            CostoPielesTotal = lote.CostoPielesTotal,
            Observacion = lote.Observacion,
            Estado = lote.Estado,
            CreadoPorUsuarioId = lote.CreadoPorUsuarioId
        };

        dbContext.Lotes.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task UpdateAsync(Lote lote, CancellationToken cancellationToken)
    {
        var entity = await dbContext.Lotes.SingleAsync(x => x.Id == lote.Id, cancellationToken);
        entity.ClienteId = lote.ClienteId;
        entity.TipoPielId = lote.TipoPielId;
        entity.FechaIngreso = lote.FechaIngreso;
        entity.CantidadPielesInicial = lote.CantidadPielesInicial;
        entity.CantidadPielesDisponible = lote.CantidadPielesDisponible;
        entity.ClienteTraeLote = lote.ClienteTraeLote;
        entity.CostoPielesTotal = lote.CostoPielesTotal;
        entity.Observacion = lote.Observacion;
        entity.Estado = lote.Estado;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public Task<bool> HasAnyOrderAsync(long loteId, CancellationToken cancellationToken) =>
        dbContext.Database.SqlQueryRaw<int>(
            "SELECT 1 WHERE EXISTS (SELECT 1 FROM produccion.orden_produccion WHERE lote_id = {0})",
            loteId).AnyAsync(cancellationToken);

    public async Task<IReadOnlyCollection<Lote>> ListAsync(LoteFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                l.id AS Id,
                l.codigo AS Codigo,
                l.cliente_id AS ClienteId,
                c.razon_social AS ClienteRazonSocial,
                l.tipo_piel_id AS TipoPielId,
                tp.codigo AS TipoPielCodigo,
                tp.nombre AS TipoPielNombre,
                l.fecha_ingreso AS FechaIngreso,
                l.cantidad_pieles_inicial AS CantidadPielesInicial,
                CONVERT(DECIMAL(18,4), l.cantidad_pieles_inicial - l.cantidad_pieles_disponible) AS CantidadPielesUtilizada,
                l.cantidad_pieles_disponible AS CantidadPielesDisponible,
                CAST(l.cantidad_pieles_inicial * 2.0 AS DECIMAL(18,2)) AS CantidadLadosCalculada,
                l.cliente_trae_lote AS ClienteTraeLote,
                l.costo_pieles_total AS CostoPielesTotal,
                l.observacion AS Observacion,
                l.estado AS Estado,
                l.creado_en AS CreadoEn,
                l.creado_por_usuario_id AS CreadoPorUsuarioId
            FROM produccion.lote l
            INNER JOIN produccion.cliente c ON c.id = l.cliente_id
            INNER JOIN configuracion.tipo_piel tp ON tp.id = l.tipo_piel_id
            WHERE (
                    @Texto IS NULL OR
                    l.codigo LIKE @TextoLike OR
                    c.razon_social LIKE @TextoLike OR
                    tp.nombre LIKE @TextoLike OR
                    tp.codigo LIKE @TextoLike OR
                    l.estado LIKE @TextoLike OR
                    ISNULL(l.observacion, '') LIKE @TextoLike OR
                    CONVERT(varchar(10), l.fecha_ingreso, 120) LIKE @TextoLike OR
                    CONVERT(varchar(30), l.cantidad_pieles_inicial) LIKE @TextoLike OR
                    CONVERT(varchar(30), l.cantidad_pieles_disponible) LIKE @TextoLike
                )
              AND (@ClienteId IS NULL OR l.cliente_id = @ClienteId)
              AND (@TipoPielId IS NULL OR l.tipo_piel_id = @TipoPielId)
              AND (@Estado IS NULL OR l.estado = @Estado)
            ORDER BY l.fecha_ingreso DESC, l.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<Lote>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.ClienteId,
                    filters.TipoPielId,
                    filters.Estado
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
