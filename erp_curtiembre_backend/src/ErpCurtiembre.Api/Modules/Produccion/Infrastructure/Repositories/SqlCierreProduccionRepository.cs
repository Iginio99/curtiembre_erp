using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Modules.Produccion.Domain.Entities;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Produccion.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;
using Microsoft.EntityFrameworkCore;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Repositories;

public sealed class SqlCierreProduccionRepository(
    ISqlConnectionFactory connectionFactory,
    ProduccionDbContext dbContext) : ICierreProduccionRepository
{
    public async Task<long> RegisterMermaAsync(MermaProceso merma, CancellationToken cancellationToken)
    {
        var entity = new MermaProcesoWriteModel
        {
            OrdenProduccionId = merma.OrdenProduccionId,
            OrdenProcesoId = merma.OrdenProcesoId,
            CantidadPerdida = merma.CantidadPerdida,
            Motivo = merma.Motivo,
            Observacion = merma.Observacion,
            RegistradoEn = merma.RegistradoEn,
            RegistradoPorUsuarioId = merma.RegistradoPorUsuarioId
        };

        dbContext.MermasProceso.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task<MermaProceso?> FindMermaByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                m.id AS Id,
                m.orden_produccion_id AS OrdenProduccionId,
                m.orden_proceso_id AS OrdenProcesoId,
                opp.proceso_productivo_id AS ProcesoProductivoId,
                pp.codigo AS ProcesoCodigo,
                pp.nombre AS ProcesoNombre,
                m.cantidad_perdida AS CantidadPerdida,
                m.motivo AS Motivo,
                m.observacion AS Observacion,
                m.registrado_en AS RegistradoEn,
                m.registrado_por_usuario_id AS RegistradoPorUsuarioId,
                CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END AS RegistradoPorNombre
            FROM produccion.merma_proceso m
            INNER JOIN produccion.orden_produccion_proceso opp ON opp.id = m.orden_proceso_id
            INNER JOIN configuracion.proceso_productivo pp ON pp.id = opp.proceso_productivo_id
            LEFT JOIN seguridad.usuario u ON u.id = m.registrado_por_usuario_id
            WHERE m.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<MermaProceso>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<long> RegisterControlCalidadAsync(ControlCalidad quality, CancellationToken cancellationToken)
    {
        var entity = new ControlCalidadWriteModel
        {
            OrdenProduccionId = quality.OrdenProduccionId,
            CalidadProductoId = quality.CalidadProductoId,
            Resultado = quality.Resultado,
            Observacion = quality.Observacion,
            EvaluadoEn = quality.EvaluadoEn,
            EvaluadoPorUsuarioId = quality.EvaluadoPorUsuarioId
        };

        dbContext.ControlesCalidad.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
        return entity.Id;
    }

    public async Task<ControlCalidad?> FindControlCalidadByIdAsync(long id, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                q.id AS Id,
                q.orden_produccion_id AS OrdenProduccionId,
                q.producto_terminado_id AS ProductoTerminadoId,
                q.calidad_producto_id AS CalidadProductoId,
                c.codigo AS CalidadCodigo,
                c.nombre AS CalidadNombre,
                q.resultado AS Resultado,
                q.observacion AS Observacion,
                q.evaluado_en AS EvaluadoEn,
                q.evaluado_por_usuario_id AS EvaluadoPorUsuarioId,
                CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END AS EvaluadoPorNombre
            FROM produccion.control_calidad q
            INNER JOIN configuracion.calidad_producto c ON c.id = q.calidad_producto_id
            LEFT JOIN seguridad.usuario u ON u.id = q.evaluado_por_usuario_id
            WHERE q.id = @Id;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ControlCalidad>(
            new CommandDefinition(sql, new { Id = id }, cancellationToken: cancellationToken));
    }

    public async Task<ControlCalidad?> FindLatestControlCalidadAsync(long orderId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                q.id AS Id,
                q.orden_produccion_id AS OrdenProduccionId,
                q.producto_terminado_id AS ProductoTerminadoId,
                q.calidad_producto_id AS CalidadProductoId,
                c.codigo AS CalidadCodigo,
                c.nombre AS CalidadNombre,
                q.resultado AS Resultado,
                q.observacion AS Observacion,
                q.evaluado_en AS EvaluadoEn,
                q.evaluado_por_usuario_id AS EvaluadoPorUsuarioId,
                CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END AS EvaluadoPorNombre
            FROM produccion.control_calidad q
            INNER JOIN configuracion.calidad_producto c ON c.id = q.calidad_producto_id
            LEFT JOIN seguridad.usuario u ON u.id = q.evaluado_por_usuario_id
            WHERE q.orden_produccion_id = @OrderId
            ORDER BY q.evaluado_en DESC, q.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ControlCalidad>(
            new CommandDefinition(sql, new { OrderId = orderId }, cancellationToken: cancellationToken));
    }

    public async Task<ProductoTerminado?> FindProductoTerminadoByOrderIdAsync(long orderId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                pt.id AS Id,
                pt.codigo AS Codigo,
                pt.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenCodigo,
                pt.calidad_producto_id AS CalidadProductoId,
                c.codigo AS CalidadCodigo,
                c.nombre AS CalidadNombre,
                pt.fecha_ingreso AS FechaIngreso,
                pt.cantidad_pieles_buenas AS CantidadPielesBuenas,
                pt.cantidad_lados_calculada AS CantidadLadosCalculada,
                pt.estado AS Estado,
                pt.observacion AS Observacion
            FROM produccion.producto_terminado pt
            INNER JOIN produccion.orden_produccion op ON op.id = pt.orden_produccion_id
            INNER JOIN configuracion.calidad_producto c ON c.id = pt.calidad_producto_id
            WHERE pt.orden_produccion_id = @OrderId;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<ProductoTerminado>(
            new CommandDefinition(sql, new { OrderId = orderId }, cancellationToken: cancellationToken));
    }

    public async Task<IReadOnlyCollection<ProductoTerminado>> ListProductosTerminadosAsync(CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                pt.id AS Id,
                pt.codigo AS Codigo,
                pt.orden_produccion_id AS OrdenProduccionId,
                op.codigo AS OrdenCodigo,
                pt.calidad_producto_id AS CalidadProductoId,
                c.codigo AS CalidadCodigo,
                c.nombre AS CalidadNombre,
                pt.fecha_ingreso AS FechaIngreso,
                pt.cantidad_pieles_buenas AS CantidadPielesBuenas,
                pt.cantidad_lados_calculada AS CantidadLadosCalculada,
                pt.estado AS Estado,
                pt.observacion AS Observacion
            FROM produccion.producto_terminado pt
            INNER JOIN produccion.orden_produccion op ON op.id = pt.orden_produccion_id
            INNER JOIN configuracion.calidad_producto c ON c.id = pt.calidad_producto_id
            ORDER BY pt.fecha_ingreso DESC, pt.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<ProductoTerminado>(
            new CommandDefinition(sql, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<long> FinalizeOrderAsync(
        FinalizacionProduccion finalizacion,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var order = await dbContext.OrdenesProduccion.SingleAsync(x => x.Id == finalizacion.OrdenProduccionId, cancellationToken);
        var lote = await dbContext.Lotes.SingleAsync(x => x.Id == order.LoteId, cancellationToken);
        var quality = await dbContext.ControlesCalidad.SingleAsync(x => x.Id == finalizacion.ControlCalidadId, cancellationToken);

        var product = new ProductoTerminadoWriteModel
        {
            Codigo = finalizacion.ProductoTerminadoCodigo,
            OrdenProduccionId = finalizacion.OrdenProduccionId,
            CalidadProductoId = finalizacion.CalidadProductoId,
            FechaIngreso = finalizacion.Timestamp,
            CantidadPielesBuenas = 0,
            CantidadLados = finalizacion.CantidadLados,
            Estado = "DISPONIBLE",
            Observacion = finalizacion.Observacion
        };

        dbContext.ProductosTerminados.Add(product);
        await dbContext.SaveChangesAsync(cancellationToken);

        quality.ProductoTerminadoId = product.Id;

        order.Estado = "FINALIZADA";
        order.FechaFinReal ??= finalizacion.Timestamp;
        order.ActualizadoEn = finalizacion.Timestamp;
        order.ActualizadoPorUsuarioId = finalizacion.ActorId;

        lote.Estado = await ResolveLoteStateAsync(lote.Id, lote.CantidadPielesDisponible, cancellationToken);

        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return product.Id;
    }

    private async Task<string> ResolveLoteStateAsync(
        long loteId,
        decimal cantidadDisponible,
        CancellationToken cancellationToken)
    {
        if (cantidadDisponible <= 0)
        {
            return "AGOTADO";
        }

        var hasActiveOrders = await dbContext.OrdenesProduccion.AnyAsync(
            x => x.LoteId == loteId &&
                 (x.Estado == "PROGRAMADA" || x.Estado == "EN_PROCESO"),
            cancellationToken);

        return hasActiveOrders ? "EN_PRODUCCION" : "DISPONIBLE";
    }
}
