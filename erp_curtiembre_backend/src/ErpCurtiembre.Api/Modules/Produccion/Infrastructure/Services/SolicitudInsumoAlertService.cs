using Dapper;
using ErpCurtiembre.Modules.Produccion.Application.Ports;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Services;

public sealed class SolicitudInsumoAlertService(ISqlConnectionFactory connectionFactory) : ISolicitudInsumoAlertService
{
    public async Task CreatePendingAsync(long solicitudId, string codigo, CancellationToken cancellationToken)
    {
        const string sql = """
            IF NOT EXISTS (
                SELECT 1 FROM alertas.alerta
                WHERE entidad_origen = 'SOLICITUD_INSUMO' AND entidad_origen_id = @SolicitudId
                  AND estado IN ('PENDIENTE', 'LEIDA'))
            BEGIN
                DECLARE @AlertaId BIGINT;
                INSERT INTO alertas.alerta
                    (tipo_alerta, severidad, titulo, mensaje, modulo_origen, entidad_origen, entidad_origen_id, estado, generada_en)
                VALUES
                    ('SOLICITUD_INSUMO_PENDIENTE', 'MEDIA', @Titulo, @Mensaje, 'PRODUCCION', 'SOLICITUD_INSUMO', @SolicitudId, 'PENDIENTE', SYSUTCDATETIME());
                SET @AlertaId = SCOPE_IDENTITY();

                INSERT INTO alertas.alerta_destinatario (alerta_id, rol_id)
                SELECT DISTINCT @AlertaId, rp.rol_id
                FROM seguridad.rol_permiso rp
                INNER JOIN seguridad.permiso p ON p.id = rp.permiso_id
                WHERE p.codigo = 'INVENTARIO_OPERACIONES';
            END;
            """;
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        await connection.ExecuteAsync(new CommandDefinition(sql, new
        {
            SolicitudId = solicitudId,
            Titulo = $"Solicitud {codigo} pendiente de entrega",
            Mensaje = "Produccion solicito insumos para una etapa. Entrega el total para habilitar su inicio."
        }, cancellationToken: cancellationToken));
    }

    public async Task CloseAsync(long solicitudId, long actorId, CancellationToken cancellationToken)
    {
        const string sql = """
            DECLARE @AlertaId BIGINT = (
                SELECT TOP 1 id FROM alertas.alerta
                WHERE entidad_origen = 'SOLICITUD_INSUMO' AND entidad_origen_id = @SolicitudId
                  AND estado IN ('PENDIENTE', 'LEIDA') ORDER BY id DESC);
            IF @AlertaId IS NOT NULL
            BEGIN
                UPDATE alertas.alerta SET estado = 'CERRADA', cerrada_en = SYSUTCDATETIME() WHERE id = @AlertaId;
                INSERT INTO alertas.alerta_historial
                    (alerta_id, estado_anterior, estado_nuevo, comentario, cambiado_por_usuario_id, cambiado_en)
                VALUES
                    (@AlertaId, 'PENDIENTE', 'CERRADA', 'Cerrada automaticamente por la entrega de la solicitud.', @ActorId, SYSUTCDATETIME());
            END;
            """;
        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        await connection.ExecuteAsync(new CommandDefinition(
            sql, new { SolicitudId = solicitudId, ActorId = actorId }, cancellationToken: cancellationToken));
    }
}
