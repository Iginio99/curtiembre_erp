using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlSolicitudInsumoRepository(
    ISqlConnectionFactory connectionFactory,
    ProduccionDbContext dbContext) : ISolicitudInsumoRepository
{
    public async Task<long> CreateAsync(
        SolicitudInsumo solicitud,
        IReadOnlyCollection<SolicitudInsumoDetalle> detalles,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var header = new SolicitudInsumoWriteModel
        {
            Codigo = solicitud.Codigo,
            OrdenProduccionId = solicitud.OrdenProduccionId,
            OrdenProcesoId = solicitud.OrdenProcesoId,
            Estado = solicitud.Estado,
            Observacion = solicitud.Observacion,
            SolicitadoEn = solicitud.SolicitadoEn,
            SolicitadoPorUsuarioId = solicitud.SolicitadoPorUsuarioId
        };
        dbContext.SolicitudesInsumo.Add(header);
        await dbContext.SaveChangesAsync(cancellationToken);

        foreach (var detail in detalles)
        {
            dbContext.SolicitudesInsumoDetalle.Add(new SolicitudInsumoDetalleWriteModel
            {
                SolicitudInsumoId = header.Id,
                InsumoId = detail.InsumoId,
                CantidadSolicitada = detail.CantidadSolicitada,
                Observacion = detail.Observacion
            });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return header.Id;
    }

    public async Task<SolicitudInsumo?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                s.id AS Id, s.codigo AS Codigo,
                s.orden_produccion_id AS OrdenProduccionId, op.codigo AS OrdenCodigo,
                s.orden_proceso_id AS OrdenProcesoId, pp.codigo AS ProcesoCodigo, pp.nombre AS ProcesoNombre,
                s.estado AS Estado, s.observacion AS Observacion, s.solicitado_en AS SolicitadoEn,
                s.solicitado_por_usuario_id AS SolicitadoPorUsuarioId,
                LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) AS SolicitadoPorNombre
            FROM produccion.solicitud_insumo s
            INNER JOIN produccion.orden_produccion op ON op.id = s.orden_produccion_id
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = s.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            INNER JOIN seguridad.usuario u ON u.id = s.solicitado_por_usuario_id
            WHERE s.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<SolicitudInsumo>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<SolicitudInsumo>> ListAsync(string? estado, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                s.id AS Id, s.codigo AS Codigo,
                s.orden_produccion_id AS OrdenProduccionId, op.codigo AS OrdenCodigo,
                s.orden_proceso_id AS OrdenProcesoId, pp.codigo AS ProcesoCodigo, pp.nombre AS ProcesoNombre,
                s.estado AS Estado, s.observacion AS Observacion, s.solicitado_en AS SolicitadoEn,
                s.solicitado_por_usuario_id AS SolicitadoPorUsuarioId,
                LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) AS SolicitadoPorNombre
            FROM produccion.solicitud_insumo s
            INNER JOIN produccion.orden_produccion op ON op.id = s.orden_produccion_id
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = s.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            INNER JOIN seguridad.usuario u ON u.id = s.solicitado_por_usuario_id
            WHERE @Estado IS NULL OR s.estado = @Estado
            ORDER BY s.solicitado_en DESC, s.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<SolicitudInsumo>(
            new CommandDefinition(sql, new { Estado = string.IsNullOrWhiteSpace(estado) ? null : estado.Trim().ToUpperInvariant() }, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<SolicitudInsumoDetalle>> ListDetailsAsync(long solicitudId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                d.id AS Id, d.solicitud_insumo_id AS SolicitudInsumoId, d.insumo_id AS InsumoId,
                i.codigo AS InsumoCodigo, i.nombre AS InsumoNombre,
                um.codigo AS UnidadMedidaCodigo, um.nombre AS UnidadMedidaNombre,
                d.cantidad_solicitada AS CantidadSolicitada, d.observacion AS Observacion
            FROM produccion.solicitud_insumo_detalle d
            INNER JOIN inventario.insumo i ON i.id = d.insumo_id
            INNER JOIN configuracion.unidad_medida um ON um.id = i.unidad_medida_id
            WHERE d.solicitud_insumo_id = @SolicitudId
            ORDER BY i.nombre, i.codigo;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<SolicitudInsumoDetalle>(
            new CommandDefinition(sql, new { SolicitudId = solicitudId }, cancellationToken: cancellationToken));
        return items.ToArray();
    }

    public Task<bool> HasOpenRequestForProcessAsync(long ordenProcesoId, CancellationToken cancellationToken) =>
        dbContext.SolicitudesInsumo.AnyAsync(
            x => x.OrdenProcesoId == ordenProcesoId &&
                (x.Estado == "SOLICITADA" || x.Estado == "APROBADA" || x.Estado == "PARCIAL"),
            cancellationToken);

    public async Task<bool> TryStartDeliveryAsync(long id, CancellationToken cancellationToken)
    {
        var affected = await dbContext.SolicitudesInsumo
            .Where(x => x.Id == id && x.Estado == "SOLICITADA")
            .ExecuteUpdateAsync(
                setters => setters.SetProperty(x => x.Estado, "ENTREGANDO"),
                cancellationToken);
        return affected == 1;
    }

    public async Task<bool> CompleteDeliveryAsync(long id, CancellationToken cancellationToken)
    {
        var affected = await dbContext.SolicitudesInsumo
            .Where(x => x.Id == id && x.Estado == "ENTREGANDO")
            .ExecuteUpdateAsync(
                setters => setters.SetProperty(x => x.Estado, "ENTREGADA"),
                cancellationToken);
        return affected == 1;
    }

    public Task ReopenDeliveryAsync(long id, CancellationToken cancellationToken) =>
        dbContext.SolicitudesInsumo
            .Where(x => x.Id == id && x.Estado == "ENTREGANDO")
            .ExecuteUpdateAsync(
                setters => setters.SetProperty(x => x.Estado, "SOLICITADA"),
                cancellationToken);
}
