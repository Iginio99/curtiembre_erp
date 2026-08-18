using Dapper;
using ErpCurtiembre.Modules.Alertas.Application.Ports;
using ErpCurtiembre.Shared.Persistence;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Alertas.Infrastructure.Services;

public sealed class SqlAlertaCommandService(
    ISqlConnectionFactory connectionFactory,
    IDateTimeProvider dateTimeProvider) : IAlertaCommandService
{
    public async Task<bool> MarkAsReadAsync(long usuarioId, long alertaId, CancellationToken cancellationToken)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);

        var alert = await GetAccessibleAlertAsync(connection, usuarioId, alertaId, cancellationToken);
        if (alert is null)
        {
            return false;
        }

        if (string.Equals(alert.Estado, "CERRADA", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(alert.Estado, "LEIDA", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        const string updateAlertSql = """
            UPDATE alertas.alerta
            SET estado = 'LEIDA',
                leida_en = COALESCE(leida_en, @LeidaEn)
            WHERE id = @AlertaId
              AND estado = 'PENDIENTE';
            """;

        const string updateRecipientsSql = """
            UPDATE ad
            SET leida = 1,
                leida_en = COALESCE(ad.leida_en, @LeidaEn)
            FROM alertas.alerta_destinatario ad
            INNER JOIN seguridad.usuario su ON su.id = @UsuarioId
            WHERE ad.alerta_id = @AlertaId
              AND (
                    ad.usuario_id = @UsuarioId
                    OR ad.rol_id = su.rol_id
                  );
            """;

        const string historySql = """
            INSERT INTO alertas.alerta_historial
            (
                alerta_id,
                estado_anterior,
                estado_nuevo,
                comentario,
                cambiado_por_usuario_id,
                cambiado_en
            )
            VALUES
            (
                @AlertaId,
                'PENDIENTE',
                'LEIDA',
                @Comentario,
                @UsuarioId,
                @CambiadoEn
            );
            """;

        await connection.ExecuteAsync(
            new CommandDefinition(
                updateAlertSql,
                new
                {
                    AlertaId = alertaId,
                    LeidaEn = dateTimeProvider.Now
                },
                cancellationToken: cancellationToken));

        await connection.ExecuteAsync(
            new CommandDefinition(
                updateRecipientsSql,
                new
                {
                    AlertaId = alertaId,
                    UsuarioId = usuarioId,
                    LeidaEn = dateTimeProvider.Now
                },
                cancellationToken: cancellationToken));

        await connection.ExecuteAsync(
            new CommandDefinition(
                historySql,
                new
                {
                    AlertaId = alertaId,
                    UsuarioId = usuarioId,
                    Comentario = "Alerta marcada como leida.",
                    CambiadoEn = dateTimeProvider.Now
                },
                cancellationToken: cancellationToken));

        return true;
    }

    public async Task<bool> CloseAsync(
        long usuarioId,
        long alertaId,
        string? comentario,
        CancellationToken cancellationToken)
    {
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);

        var alert = await GetAccessibleAlertAsync(connection, usuarioId, alertaId, cancellationToken);
        if (alert is null)
        {
            return false;
        }

        if (string.Equals(alert.Estado, "CERRADA", StringComparison.OrdinalIgnoreCase))
        {
            return true;
        }

        const string closeAlertSql = """
            UPDATE alertas.alerta
            SET estado = 'CERRADA',
                cerrada_en = COALESCE(cerrada_en, @CerradaEn),
                leida_en = COALESCE(leida_en, @CerradaEn)
            WHERE id = @AlertaId
              AND estado IN ('PENDIENTE', 'LEIDA');
            """;

        const string updateRecipientsSql = """
            UPDATE ad
            SET leida = 1,
                leida_en = COALESCE(ad.leida_en, @LeidaEn)
            FROM alertas.alerta_destinatario ad
            INNER JOIN seguridad.usuario su ON su.id = @UsuarioId
            WHERE ad.alerta_id = @AlertaId
              AND (
                    ad.usuario_id = @UsuarioId
                    OR ad.rol_id = su.rol_id
                  );
            """;

        const string historySql = """
            INSERT INTO alertas.alerta_historial
            (
                alerta_id,
                estado_anterior,
                estado_nuevo,
                comentario,
                cambiado_por_usuario_id,
                cambiado_en
            )
            VALUES
            (
                @AlertaId,
                @EstadoAnterior,
                'CERRADA',
                @Comentario,
                @UsuarioId,
                @CambiadoEn
            );
            """;

        await connection.ExecuteAsync(
            new CommandDefinition(
                closeAlertSql,
                new
                {
                    AlertaId = alertaId,
                    CerradaEn = dateTimeProvider.Now
                },
                cancellationToken: cancellationToken));

        await connection.ExecuteAsync(
            new CommandDefinition(
                updateRecipientsSql,
                new
                {
                    AlertaId = alertaId,
                    UsuarioId = usuarioId,
                    LeidaEn = dateTimeProvider.Now
                },
                cancellationToken: cancellationToken));

        await connection.ExecuteAsync(
            new CommandDefinition(
                historySql,
                new
                {
                    AlertaId = alertaId,
                    EstadoAnterior = alert.Estado,
                    Comentario = string.IsNullOrWhiteSpace(comentario)
                        ? "Alerta cerrada manualmente."
                        : comentario.Trim(),
                    UsuarioId = usuarioId,
                    CambiadoEn = dateTimeProvider.Now
                },
                cancellationToken: cancellationToken));

        return true;
    }

    private static async Task<AccessibleAlertRow?> GetAccessibleAlertAsync(
        System.Data.IDbConnection connection,
        long usuarioId,
        long alertaId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT TOP 1
                a.id AS Id,
                a.estado AS Estado
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
                                ad.usuario_id = @UsuarioId
                                OR ad.rol_id = su.rol_id
                              )
                    )
                );
            """;

        return await connection.QuerySingleOrDefaultAsync<AccessibleAlertRow>(
            new CommandDefinition(
                sql,
                new
                {
                    UsuarioId = usuarioId,
                    AlertaId = alertaId
                },
                cancellationToken: cancellationToken));
    }

    private sealed record AccessibleAlertRow(long Id, string Estado);
}
