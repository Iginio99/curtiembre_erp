using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.DTOs;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlOrdenProduccionRepository(
    ISqlConnectionFactory connectionFactory,
    ProduccionDbContext dbContext) : IOrdenProduccionRepository
{
    public async Task<long> CreateAsync(
        OrdenProduccion orden,
        IReadOnlyCollection<ProcesoProductivoLookup> procesos,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var lote = await dbContext.Lotes.SingleAsync(x => x.Id == orden.LoteId, cancellationToken);
        if (lote.Estado == "ANULADO")
        {
            throw new InvalidOperationException("No se puede reservar un lote anulado.");
        }

        if (lote.CantidadPielesDisponible < orden.CantidadPieles)
        {
            throw new InvalidOperationException("La cantidad solicitada supera la disponibilidad actual del lote.");
        }

        var entity = new OrdenProduccionWriteModel
        {
            Codigo = orden.Codigo,
            LoteId = orden.LoteId,
            ClienteId = orden.ClienteId,
            CantidadPieles = orden.CantidadPieles,
            FechaInicioPlanificada = orden.FechaInicioPlanificada,
            FechaFinEstimada = orden.FechaFinEstimada,
            ResponsableNombre = orden.ResponsableNombre,
            ResponsableCargo = orden.ResponsableCargo,
            Estado = orden.Estado,
            Observacion = orden.Observacion,
            CreadoPorUsuarioId = orden.CreadoPorUsuarioId
        };

        dbContext.OrdenesProduccion.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);

        foreach (var proceso in procesos)
        {
            dbContext.OrdenesProduccionProceso.Add(new OrdenProduccionProcesoWriteModel
            {
                OrdenProduccionId = entity.Id,
                ProcesoProductivoId = proceso.Id,
                Secuencia = proceso.OrdenSecuencia,
                Estado = "PENDIENTE"
            });
        }

        lote.CantidadPielesDisponible = decimal.Round(lote.CantidadPielesDisponible - orden.CantidadPieles, 4);
        lote.Estado = lote.CantidadPielesDisponible <= 0 ? "AGOTADO" : "EN_PRODUCCION";

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return entity.Id;
    }

    public async Task<OrdenProduccion?> FindByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                op.id AS Id,
                op.codigo AS Codigo,
                op.lote_id AS LoteId,
                l.codigo AS LoteCodigo,
                op.cliente_id AS ClienteId,
                c.razon_social AS ClienteRazonSocial,
                op.cantidad_pieles AS CantidadPieles,
                op.fecha_inicio_planificada AS FechaInicioPlanificada,
                op.fecha_inicio_real AS FechaInicioReal,
                op.fecha_fin_estimada AS FechaFinEstimada,
                op.fecha_fin_real AS FechaFinReal,
                op.responsable_usuario_id AS ResponsableUsuarioId,
                COALESCE(op.responsable_nombre, CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END) AS ResponsableNombre,
                op.responsable_cargo AS ResponsableCargo,
                op.estado AS Estado,
                op.motivo_anulacion AS MotivoAnulacion,
                op.observacion AS Observacion,
                COUNT(opp.id) AS ProcesosTotales,
                SUM(CASE WHEN opp.estado = 'FINALIZADO' THEN 1 ELSE 0 END) AS ProcesosFinalizados,
                op.creado_en AS CreadoEn,
                op.creado_por_usuario_id AS CreadoPorUsuarioId,
                op.actualizado_en AS ActualizadoEn,
                op.actualizado_por_usuario_id AS ActualizadoPorUsuarioId
            FROM produccion.orden_produccion op
            INNER JOIN produccion.lote l ON l.id = op.lote_id
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            LEFT JOIN seguridad.usuario u ON u.id = op.responsable_usuario_id
            LEFT JOIN produccion.orden_produccion_proceso opp ON opp.orden_produccion_id = op.id
            WHERE op.id = @Id
            GROUP BY
                op.id,
                op.codigo,
                op.lote_id,
                l.codigo,
                op.cliente_id,
                c.razon_social,
                op.cantidad_pieles,
                op.fecha_inicio_planificada,
                op.fecha_inicio_real,
                op.fecha_fin_estimada,
                op.fecha_fin_real,
                op.responsable_usuario_id,
                op.responsable_nombre,
                op.responsable_cargo,
                u.id,
                u.nombres,
                u.apellidos,
                op.estado,
                op.motivo_anulacion,
                op.observacion,
                op.creado_en,
                op.creado_por_usuario_id,
                op.actualizado_en,
                op.actualizado_por_usuario_id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<OrdenProduccion>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<OrdenProduccion>> ListAsync(
        OrdenProduccionFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                op.id AS Id,
                op.codigo AS Codigo,
                op.lote_id AS LoteId,
                l.codigo AS LoteCodigo,
                op.cliente_id AS ClienteId,
                c.razon_social AS ClienteRazonSocial,
                op.cantidad_pieles AS CantidadPieles,
                op.fecha_inicio_planificada AS FechaInicioPlanificada,
                op.fecha_inicio_real AS FechaInicioReal,
                op.fecha_fin_estimada AS FechaFinEstimada,
                op.fecha_fin_real AS FechaFinReal,
                op.responsable_usuario_id AS ResponsableUsuarioId,
                COALESCE(op.responsable_nombre, CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END) AS ResponsableNombre,
                op.responsable_cargo AS ResponsableCargo,
                op.estado AS Estado,
                op.motivo_anulacion AS MotivoAnulacion,
                op.observacion AS Observacion,
                COUNT(opp.id) AS ProcesosTotales,
                SUM(CASE WHEN opp.estado = 'FINALIZADO' THEN 1 ELSE 0 END) AS ProcesosFinalizados,
                op.creado_en AS CreadoEn,
                op.creado_por_usuario_id AS CreadoPorUsuarioId,
                op.actualizado_en AS ActualizadoEn,
                op.actualizado_por_usuario_id AS ActualizadoPorUsuarioId
            FROM produccion.orden_produccion op
            INNER JOIN produccion.lote l ON l.id = op.lote_id
            INNER JOIN produccion.cliente c ON c.id = op.cliente_id
            LEFT JOIN seguridad.usuario u ON u.id = op.responsable_usuario_id
            LEFT JOIN produccion.orden_produccion_proceso opp ON opp.orden_produccion_id = op.id
            WHERE (
                    @Texto IS NULL OR
                    op.codigo LIKE @TextoLike OR
                    l.codigo LIKE @TextoLike OR
                    c.razon_social LIKE @TextoLike
                )
              AND (@ClienteId IS NULL OR op.cliente_id = @ClienteId)
              AND (@LoteId IS NULL OR op.lote_id = @LoteId)
              AND (@Estado IS NULL OR op.estado = @Estado)
            GROUP BY
                op.id,
                op.codigo,
                op.lote_id,
                l.codigo,
                op.cliente_id,
                c.razon_social,
                op.cantidad_pieles,
                op.fecha_inicio_planificada,
                op.fecha_inicio_real,
                op.fecha_fin_estimada,
                op.fecha_fin_real,
                op.responsable_usuario_id,
                op.responsable_nombre,
                op.responsable_cargo,
                u.id,
                u.nombres,
                u.apellidos,
                op.estado,
                op.motivo_anulacion,
                op.observacion,
                op.creado_en,
                op.creado_por_usuario_id,
                op.actualizado_en,
                op.actualizado_por_usuario_id
            ORDER BY op.creado_en DESC, op.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<OrdenProduccion>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.Texto,
                    TextoLike = filters.Texto is null ? null : $"%{filters.Texto}%",
                    filters.ClienteId,
                    filters.LoteId,
                    filters.Estado
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<OrdenProduccionProceso>> ListProcessesAsync(
        long ordenId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                opp.id AS Id,
                opp.orden_produccion_id AS OrdenProduccionId,
                op.estado AS OrdenEstado,
                opp.proceso_productivo_id AS ProcesoProductivoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                opp.secuencia AS Secuencia,
                opp.responsable_usuario_id AS ResponsableUsuarioId,
                COALESCE(opp.responsable_nombre, CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END) AS ResponsableNombre,
                opp.responsable_cargo AS ResponsableCargo,
                opp.peso_base_kg AS PesoBaseKg,
                opp.fecha_fin_estimada AS FechaFinEstimada,
                opp.fecha_inicio AS FechaInicio,
                opp.fecha_fin AS FechaFin,
                opp.dias_reales AS DiasReales,
                opp.estado AS Estado,
                opp.observacion AS Observacion
            FROM produccion.orden_produccion_proceso opp
            INNER JOIN produccion.orden_produccion op ON op.id = opp.orden_produccion_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            LEFT JOIN seguridad.usuario u ON u.id = opp.responsable_usuario_id
            WHERE opp.orden_produccion_id = @OrdenId
            ORDER BY opp.secuencia, opp.id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<OrdenProduccionProceso>(
            new CommandDefinition(sql, new { OrdenId = ordenId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<OrdenProduccionProceso?> FindProcessByIdAsync(long processId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                opp.id AS Id,
                opp.orden_produccion_id AS OrdenProduccionId,
                op.estado AS OrdenEstado,
                opp.proceso_productivo_id AS ProcesoProductivoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                opp.secuencia AS Secuencia,
                opp.responsable_usuario_id AS ResponsableUsuarioId,
                COALESCE(opp.responsable_nombre, CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END) AS ResponsableNombre,
                opp.responsable_cargo AS ResponsableCargo,
                opp.peso_base_kg AS PesoBaseKg,
                opp.fecha_fin_estimada AS FechaFinEstimada,
                opp.fecha_inicio AS FechaInicio,
                opp.fecha_fin AS FechaFin,
                opp.dias_reales AS DiasReales,
                opp.estado AS Estado,
                opp.observacion AS Observacion
            FROM produccion.orden_produccion_proceso opp
            INNER JOIN produccion.orden_produccion op ON op.id = opp.orden_produccion_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            LEFT JOIN seguridad.usuario u ON u.id = opp.responsable_usuario_id
            WHERE opp.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<OrdenProduccionProceso>(
            new CommandDefinition(sql, new { Id = processId }, cancellationToken: cancellationToken));
    }

    public async Task StartOrderAsync(
        long orderId,
        string responsableNombre,
        string responsableCargo,
        decimal pesoBaseKg,
        DateTime fechaFinEstimada,
        string? observacion,
        DateTime startedAt,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var order = await dbContext.OrdenesProduccion.SingleAsync(x => x.Id == orderId, cancellationToken);
        var firstProcess = await dbContext.OrdenesProduccionProceso
            .Where(x => x.OrdenProduccionId == orderId)
            .OrderBy(x => x.Secuencia)
            .ThenBy(x => x.Id)
            .FirstAsync(cancellationToken);

        order.Estado = "EN_PROCESO";
        order.FechaInicioReal = startedAt;
        order.ResponsableNombre = responsableNombre;
        order.ResponsableCargo = responsableCargo;
        if (observacion is not null)
        {
            order.Observacion = observacion;
        }

        firstProcess.Estado = "EN_PROCESO";
        firstProcess.PesoBaseKg = pesoBaseKg;
        firstProcess.FechaFinEstimada = fechaFinEstimada.Date;
        firstProcess.FechaInicio = startedAt;
        firstProcess.ResponsableNombre = responsableNombre;
        firstProcess.ResponsableCargo = responsableCargo;

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task CancelOrderAsync(
        long orderId,
        string motivo,
        long actorId,
        DateTime timestamp,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var order = await dbContext.OrdenesProduccion.SingleAsync(x => x.Id == orderId, cancellationToken);
        var lote = await dbContext.Lotes.SingleAsync(x => x.Id == order.LoteId, cancellationToken);

        order.Estado = "CANCELADA";
        order.MotivoAnulacion = motivo;
        order.ActualizadoEn = timestamp;
        order.ActualizadoPorUsuarioId = actorId;

        lote.CantidadPielesDisponible = decimal.Round(lote.CantidadPielesDisponible + order.CantidadPieles, 4);
        lote.Estado = await ResolveLoteStateAsync(lote.Id, lote.CantidadPielesDisponible, order.Id, cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task StartProcessAsync(
        long processId,
        string responsableNombre,
        string responsableCargo,
        decimal pesoBaseKg,
        DateTime fechaFinEstimada,
        string? observacion,
        DateTime startedAt,
        CancellationToken cancellationToken)
    {
        var process = await dbContext.OrdenesProduccionProceso.SingleAsync(x => x.Id == processId, cancellationToken);
        var order = await dbContext.OrdenesProduccion.SingleAsync(x => x.Id == process.OrdenProduccionId, cancellationToken);
        process.Estado = "EN_PROCESO";
        process.FechaInicio ??= startedAt;
        process.PesoBaseKg = pesoBaseKg;
        process.FechaFinEstimada = fechaFinEstimada.Date;
        process.ResponsableNombre = responsableNombre;
        process.ResponsableCargo = responsableCargo;
        order.Estado = "EN_PROCESO";
        if (observacion is not null)
        {
            process.Observacion = observacion;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task ExecuteProcessAsync(long processId, DateTime startedAt, CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        var process = await dbContext.OrdenesProduccionProceso.SingleAsync(x => x.Id == processId, cancellationToken);
        var order = await dbContext.OrdenesProduccion.SingleAsync(x => x.Id == process.OrdenProduccionId, cancellationToken);
        process.Estado = "EN_PROCESO";
        process.FechaInicio = startedAt;
        order.Estado = "EN_PROCESO";
        order.FechaInicioReal ??= startedAt;
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task MarkProcessReadyToStartAsync(long processId, CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        var process = await dbContext.OrdenesProduccionProceso.SingleAsync(x => x.Id == processId, cancellationToken);
        var order = await dbContext.OrdenesProduccion.SingleAsync(x => x.Id == process.OrdenProduccionId, cancellationToken);
        process.Estado = process.FechaInicio.HasValue ? "EN_PROCESO" : "LISTA_PARA_INICIAR";
        order.Estado = process.FechaInicio.HasValue ? "EN_PROCESO" : "LISTA_PARA_INICIAR";
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task FinishProcessAsync(
        long processId,
        string? observacion,
        DateTime finishedAt,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var process = await dbContext.OrdenesProduccionProceso.SingleAsync(x => x.Id == processId, cancellationToken);
        process.Estado = "FINALIZADO";
        process.FechaFin = finishedAt;
        if (observacion is not null)
        {
            process.Observacion = observacion;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
    }

    public async Task UpdateProcessObservationAsync(
        long processId,
        string? observacion,
        CancellationToken cancellationToken)
    {
        var process = await dbContext.OrdenesProduccionProceso.SingleAsync(x => x.Id == processId, cancellationToken);
        process.Observacion = observacion;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateOrderResponsibleAsync(long orderId, long responsableUsuarioId, CancellationToken cancellationToken)
    {
        var order = await dbContext.OrdenesProduccion.SingleAsync(x => x.Id == orderId, cancellationToken);
        order.ResponsableUsuarioId = responsableUsuarioId;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateProcessResponsibleAsync(long processId, long responsableUsuarioId, CancellationToken cancellationToken)
    {
        var process = await dbContext.OrdenesProduccionProceso.SingleAsync(x => x.Id == processId, cancellationToken);
        process.ResponsableUsuarioId = responsableUsuarioId;
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<string> ResolveLoteStateAsync(
        long loteId,
        decimal cantidadDisponible,
        long? excludeOrderId,
        CancellationToken cancellationToken)
    {
        if (cantidadDisponible <= 0)
        {
            return "AGOTADO";
        }

        var hasActiveOrders = await dbContext.OrdenesProduccion.AnyAsync(
            x => x.LoteId == loteId &&
                 (!excludeOrderId.HasValue || x.Id != excludeOrderId.Value) &&
                 (x.Estado == "PROGRAMADA" || x.Estado == "ESPERANDO_MATERIALES" || x.Estado == "LISTA_PARA_INICIAR" || x.Estado == "EN_PROCESO"),
            cancellationToken);

        return hasActiveOrders ? "EN_PRODUCCION" : "DISPONIBLE";
    }
}
