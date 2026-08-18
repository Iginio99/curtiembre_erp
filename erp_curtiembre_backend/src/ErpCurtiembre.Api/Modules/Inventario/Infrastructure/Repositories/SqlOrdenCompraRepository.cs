using Dapper;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Repositories;

public sealed class SqlOrdenCompraRepository(
    ISqlConnectionFactory connectionFactory,
    InventarioDbContext dbContext) : IOrdenCompraRepository
{
    public async Task<long> CreateAsync(OrdenCompraRegistration registration, CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var entity = new OrdenCompraWriteModel
        {
            Codigo = registration.Codigo,
            ProveedorId = registration.ProveedorId,
            FechaEmision = registration.FechaEmision.Date,
            Estado = "PENDIENTE",
            Observacion = registration.Observacion,
            CreadoPorUsuarioId = registration.ActorId
        };

        dbContext.OrdenesCompra.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        foreach (var detail in registration.Detalles)
        {
            dbContext.OrdenesCompraDetalle.Add(new OrdenCompraDetalleWriteModel
            {
                OrdenCompraId = entity.Id,
                InsumoId = detail.InsumoId,
                CantidadSolicitada = detail.CantidadSolicitada,
                CantidadRecibida = 0,
                CostoUnitarioEstimado = detail.CostoUnitarioEstimado,
                Observacion = detail.Observacion
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return entity.Id;
    }

    public async Task<OrdenCompra?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                oc.id AS Id,
                oc.codigo AS Codigo,
                oc.proveedor_id AS ProveedorId,
                p.razon_social AS ProveedorRazonSocial,
                CAST(oc.fecha_emision AS datetime2) AS FechaEmision,
                oc.fecha_aprobacion AS FechaAprobacion,
                oc.aprobado_por_usuario_id AS AprobadoPorUsuarioId,
                oc.estado AS Estado,
                oc.observacion AS Observacion,
                oc.motivo_anulacion AS Motivo,
                oc.creado_en AS CreadoEn,
                oc.creado_por_usuario_id AS CreadoPorUsuarioId,
                oc.actualizado_en AS ActualizadoEn,
                oc.actualizado_por_usuario_id AS ActualizadoPorUsuarioId,
                COUNT(d.id) AS TotalItems,
                ISNULL(SUM(d.cantidad_solicitada), 0) AS CantidadTotalSolicitada,
                ISNULL(SUM(d.cantidad_recibida), 0) AS CantidadTotalRecibida,
                ISNULL(SUM(ISNULL(d.costo_unitario_estimado, 0) * d.cantidad_solicitada), 0) AS MontoTotalEstimado
            FROM inventario.orden_compra oc
            INNER JOIN inventario.proveedor p ON p.id = oc.proveedor_id
            LEFT JOIN inventario.orden_compra_detalle d ON d.orden_compra_id = oc.id
            WHERE oc.id = @Id
            GROUP BY
                oc.id,
                oc.codigo,
                oc.proveedor_id,
                p.razon_social,
                oc.fecha_emision,
                oc.fecha_aprobacion,
                oc.aprobado_por_usuario_id,
                oc.estado,
                oc.observacion,
                oc.motivo_anulacion,
                oc.creado_en,
                oc.creado_por_usuario_id,
                oc.actualizado_en,
                oc.actualizado_por_usuario_id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<OrdenCompra>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<OrdenCompraDetalle>> ListDetailsAsync(long ordenCompraId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.id AS Id,
                d.orden_compra_id AS OrdenCompraId,
                d.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo,
                i.nombre AS InsumoNombre,
                um.codigo AS UnidadMedidaCodigo,
                um.nombre AS UnidadMedidaNombre,
                d.cantidad_solicitada AS CantidadSolicitada,
                d.cantidad_recibida AS CantidadRecibida,
                d.saldo_pendiente AS SaldoPendiente,
                d.costo_unitario_estimado AS CostoUnitarioEstimado,
                ISNULL(d.costo_unitario_estimado, 0) * d.cantidad_solicitada AS MontoEstimado,
                d.observacion AS Observacion
            FROM inventario.orden_compra_detalle d
            INNER JOIN inventario.insumo i ON i.id = d.insumo_id
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            WHERE d.orden_compra_id = @OrdenCompraId
            ORDER BY i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var details = await connection.QueryAsync<OrdenCompraDetalle>(
            new CommandDefinition(sql, new { OrdenCompraId = ordenCompraId }, cancellationToken: cancellationToken));

        return details.ToArray();
    }

    public async Task<IReadOnlyCollection<OrdenCompra>> ListAsync(OrdenCompraFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                oc.id AS Id,
                oc.codigo AS Codigo,
                oc.proveedor_id AS ProveedorId,
                p.razon_social AS ProveedorRazonSocial,
                CAST(oc.fecha_emision AS datetime2) AS FechaEmision,
                oc.fecha_aprobacion AS FechaAprobacion,
                oc.aprobado_por_usuario_id AS AprobadoPorUsuarioId,
                oc.estado AS Estado,
                oc.observacion AS Observacion,
                oc.motivo_anulacion AS Motivo,
                oc.creado_en AS CreadoEn,
                oc.creado_por_usuario_id AS CreadoPorUsuarioId,
                oc.actualizado_en AS ActualizadoEn,
                oc.actualizado_por_usuario_id AS ActualizadoPorUsuarioId,
                COUNT(d.id) AS TotalItems,
                ISNULL(SUM(d.cantidad_solicitada), 0) AS CantidadTotalSolicitada,
                ISNULL(SUM(d.cantidad_recibida), 0) AS CantidadTotalRecibida,
                ISNULL(SUM(ISNULL(d.costo_unitario_estimado, 0) * d.cantidad_solicitada), 0) AS MontoTotalEstimado
            FROM inventario.orden_compra oc
            INNER JOIN inventario.proveedor p ON p.id = oc.proveedor_id
            LEFT JOIN inventario.orden_compra_detalle d ON d.orden_compra_id = oc.id
            WHERE (
                    @Texto IS NULL OR
                    oc.codigo LIKE @TextoLike OR
                    p.razon_social LIKE @TextoLike OR
                    oc.observacion LIKE @TextoLike
                )
              AND (@ProveedorId IS NULL OR oc.proveedor_id = @ProveedorId)
              AND (@Estado IS NULL OR oc.estado = @Estado)
              AND (@FechaDesde IS NULL OR oc.fecha_emision >= @FechaDesde)
              AND (@FechaHasta IS NULL OR oc.fecha_emision <= @FechaHasta)
            GROUP BY
                oc.id,
                oc.codigo,
                oc.proveedor_id,
                p.razon_social,
                oc.fecha_emision,
                oc.fecha_aprobacion,
                oc.aprobado_por_usuario_id,
                oc.estado,
                oc.observacion,
                oc.motivo_anulacion,
                oc.creado_en,
                oc.creado_por_usuario_id,
                oc.actualizado_en,
                oc.actualizado_por_usuario_id
            ORDER BY oc.fecha_emision DESC, oc.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<OrdenCompra>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.ProveedorId,
                    filters.Estado,
                    FechaDesde = filters.FechaDesde?.Date,
                    FechaHasta = filters.FechaHasta?.Date
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task SetApprovedAsync(long id, DateTime approvedAt, long actorId, CancellationToken cancellationToken)
    {
        var entity = await dbContext.OrdenesCompra.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Estado = "APROBADA";
        entity.FechaAprobacion = approvedAt;
        entity.AprobadoPorUsuarioId = actorId;
        entity.ActualizadoEn = approvedAt;
        entity.ActualizadoPorUsuarioId = actorId;
        entity.MotivoAnulacion = null;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetRejectedAsync(long id, string motivo, DateTime updatedAt, long actorId, CancellationToken cancellationToken)
    {
        var entity = await dbContext.OrdenesCompra.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Estado = "RECHAZADA";
        entity.ActualizadoEn = updatedAt;
        entity.ActualizadoPorUsuarioId = actorId;
        entity.MotivoAnulacion = motivo;

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task SetCancelledAsync(long id, string motivo, DateTime updatedAt, long actorId, CancellationToken cancellationToken)
    {
        var entity = await dbContext.OrdenesCompra.SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity is null)
        {
            return;
        }

        entity.Estado = "ANULADA";
        entity.ActualizadoEn = updatedAt;
        entity.ActualizadoPorUsuarioId = actorId;
        entity.MotivoAnulacion = motivo;

        await dbContext.SaveChangesAsync(cancellationToken);
    }
}
