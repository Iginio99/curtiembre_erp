using ErpCurtiembre.Modules.Alertas.Application.DTOs;
using Dapper;
using ErpCurtiembre.Modules.Alertas.Application.Ports;
using ErpCurtiembre.Modules.Alertas.Domain.Entities;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Alertas.Infrastructure.Services;

public sealed class SqlAlertaQueryService(ISqlConnectionFactory connectionFactory) : IAlertaQueryService
{
    public async Task<IReadOnlyCollection<AlertaSistema>> ListActivasAsync(
        long usuarioId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                a.id AS Id,
                a.tipo_alerta AS TipoAlerta,
                a.titulo AS Titulo,
                a.mensaje AS Mensaje,
                a.severidad AS Severidad,
                a.estado AS Estado,
                a.modulo_origen AS ModuloOrigen,
                a.entidad_origen AS EntidadOrigen,
                a.entidad_origen_id AS EntidadOrigenId,
                a.generada_en AS GeneradaEn
            FROM alertas.alerta a
            INNER JOIN seguridad.usuario su ON su.id = @UsuarioId
            WHERE a.estado IN ('PENDIENTE', 'LEIDA')
              AND (
                    NOT EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                    )
                    OR EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                          AND (
                                ad.usuario_id = @UsuarioId OR
                                ad.rol_id = su.rol_id
                              )
                    )
                )
            ORDER BY a.generada_en DESC, a.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<AlertaSistema>(
            new CommandDefinition(sql, new { UsuarioId = usuarioId }, cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<IReadOnlyCollection<AlertaSistema>> ListAsync(
        long usuarioId,
        AlertaFiltersDto filters,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                a.id AS Id,
                a.tipo_alerta AS TipoAlerta,
                a.titulo AS Titulo,
                a.mensaje AS Mensaje,
                a.severidad AS Severidad,
                a.estado AS Estado,
                a.modulo_origen AS ModuloOrigen,
                a.entidad_origen AS EntidadOrigen,
                a.entidad_origen_id AS EntidadOrigenId,
                a.generada_en AS GeneradaEn
            FROM alertas.alerta a
            INNER JOIN seguridad.usuario su ON su.id = @UsuarioId
            WHERE (@Estado IS NULL OR a.estado = @Estado)
              AND (@Severidad IS NULL OR a.severidad = @Severidad)
              AND (@TipoAlerta IS NULL OR a.tipo_alerta = @TipoAlerta)
              AND (@ModuloOrigen IS NULL OR a.modulo_origen = @ModuloOrigen)
              AND (@FechaDesde IS NULL OR a.generada_en >= @FechaDesde)
              AND (@FechaHasta IS NULL OR a.generada_en <= @FechaHasta)
              AND (
                    NOT EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                    )
                    OR EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                          AND (
                                ad.usuario_id = @UsuarioId OR
                                ad.rol_id = su.rol_id
                              )
                    )
                )
            ORDER BY a.generada_en DESC, a.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<AlertaSistema>(
            new CommandDefinition(
                sql,
                new
                {
                    UsuarioId = usuarioId,
                    filters.Estado,
                    filters.Severidad,
                    filters.TipoAlerta,
                    filters.ModuloOrigen,
                    filters.FechaDesde,
                    filters.FechaHasta
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    public async Task<AlertaDetalle?> FindByIdAsync(long usuarioId, long alertaId, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                a.id AS Id,
                a.tipo_alerta AS TipoAlerta,
                a.titulo AS Titulo,
                a.mensaje AS Mensaje,
                a.severidad AS Severidad,
                a.estado AS Estado,
                a.modulo_origen AS ModuloOrigen,
                a.entidad_origen AS EntidadOrigen,
                a.entidad_origen_id AS EntidadOrigenId,
                a.generada_en AS GeneradaEn,
                a.leida_en AS LeidaEn,
                a.cerrada_en AS CerradaEn
            FROM alertas.alerta a
            INNER JOIN seguridad.usuario su ON su.id = @UsuarioId
            WHERE a.id = @AlertaId
              AND (
                    NOT EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                    )
                    OR EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                          AND (
                                ad.usuario_id = @UsuarioId OR
                                ad.rol_id = su.rol_id
                              )
                    )
                );
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<AlertaDetalle>(
            new CommandDefinition(
                sql,
                new
                {
                    UsuarioId = usuarioId,
                    AlertaId = alertaId
                },
                cancellationToken: cancellationToken));
    }

    public async Task<ResumenAlertas> GetSummaryAsync(long usuarioId, CancellationToken cancellationToken)
    {
        const string countersSql = """
            SELECT
                SUM(CASE WHEN a.estado = 'PENDIENTE' THEN 1 ELSE 0 END) AS TotalPendientes,
                SUM(CASE WHEN a.estado = 'LEIDA' THEN 1 ELSE 0 END) AS TotalLeidas,
                SUM(CASE WHEN a.estado IN ('PENDIENTE','LEIDA') AND a.severidad = 'ALTA' THEN 1 ELSE 0 END) AS TotalAlta,
                SUM(CASE WHEN a.estado IN ('PENDIENTE','LEIDA') AND a.severidad = 'MEDIA' THEN 1 ELSE 0 END) AS TotalMedia,
                SUM(CASE WHEN a.estado IN ('PENDIENTE','LEIDA') AND a.severidad = 'BAJA' THEN 1 ELSE 0 END) AS TotalBaja
            FROM alertas.alerta a
            INNER JOIN seguridad.usuario su ON su.id = @UsuarioId
            WHERE a.estado IN ('PENDIENTE','LEIDA')
              AND (
                    NOT EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                    )
                    OR EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                          AND (
                                ad.usuario_id = @UsuarioId OR
                                ad.rol_id = su.rol_id
                              )
                    )
                );
            """;

        const string recentSql = """
            SELECT TOP 5
                a.id AS Id,
                a.tipo_alerta AS TipoAlerta,
                a.titulo AS Titulo,
                a.mensaje AS Mensaje,
                a.severidad AS Severidad,
                a.estado AS Estado,
                a.modulo_origen AS ModuloOrigen,
                a.entidad_origen AS EntidadOrigen,
                a.entidad_origen_id AS EntidadOrigenId,
                a.generada_en AS GeneradaEn
            FROM alertas.alerta a
            INNER JOIN seguridad.usuario su ON su.id = @UsuarioId
            WHERE a.estado IN ('PENDIENTE','LEIDA')
              AND (
                    NOT EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                    )
                    OR EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                          AND (
                                ad.usuario_id = @UsuarioId OR
                                ad.rol_id = su.rol_id
                              )
                    )
                )
            ORDER BY a.generada_en DESC, a.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var summary = await connection.QuerySingleAsync<AlertSummaryRow>(
            new CommandDefinition(countersSql, new { UsuarioId = usuarioId }, cancellationToken: cancellationToken));

        var recientes = await connection.QueryAsync<AlertaSistema>(
            new CommandDefinition(recentSql, new { UsuarioId = usuarioId }, cancellationToken: cancellationToken));

        return new ResumenAlertas(
            summary.TotalPendientes,
            summary.TotalLeidas,
            summary.TotalAlta,
            summary.TotalMedia,
            summary.TotalBaja,
            recientes.ToArray());
    }

    public async Task<IReadOnlyCollection<AlertaHistorialItem>> ListHistorialAsync(
        long usuarioId,
        long alertaId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                h.id AS Id,
                h.estado_anterior AS EstadoAnterior,
                h.estado_nuevo AS EstadoNuevo,
                h.comentario AS Comentario,
                h.cambiado_por_usuario_id AS CambiadoPorUsuarioId,
                CASE WHEN u.id IS NULL THEN NULL ELSE LTRIM(RTRIM(CONCAT(u.nombres, ' ', u.apellidos))) END AS CambiadoPorNombre,
                h.cambiado_en AS CambiadoEn
            FROM alertas.alerta_historial h
            INNER JOIN alertas.alerta a ON a.id = h.alerta_id
            INNER JOIN seguridad.usuario su ON su.id = @UsuarioId
            LEFT JOIN seguridad.usuario u ON u.id = h.cambiado_por_usuario_id
            WHERE h.alerta_id = @AlertaId
              AND (
                    NOT EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                    )
                    OR EXISTS (
                        SELECT 1
                        FROM alertas.alerta_destinatario ad
                        WHERE ad.alerta_id = a.id
                          AND (
                                ad.usuario_id = @UsuarioId OR
                                ad.rol_id = su.rol_id
                              )
                    )
                )
            ORDER BY h.cambiado_en DESC, h.id DESC;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<AlertaHistorialItem>(
            new CommandDefinition(
                sql,
                new
                {
                    UsuarioId = usuarioId,
                    AlertaId = alertaId
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }

    private sealed record AlertSummaryRow(
        int TotalPendientes,
        int TotalLeidas,
        int TotalAlta,
        int TotalMedia,
        int TotalBaja);
}
