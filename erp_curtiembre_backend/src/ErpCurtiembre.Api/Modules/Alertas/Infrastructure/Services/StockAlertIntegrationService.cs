using Dapper;
using ErpCurtiembre.Modules.Alertas.Application.Ports;
using ErpCurtiembre.Shared.Persistence;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Alertas.Infrastructure.Services;

public sealed class StockAlertIntegrationService(
    ISqlConnectionFactory connectionFactory,
    IDateTimeProvider dateTimeProvider) : IStockAlertIntegrationService
{
    public async Task SyncLowStockAlertsAsync(IReadOnlyCollection<long> insumoIds, CancellationToken cancellationToken)
    {
        var ids = insumoIds
            .Distinct()
            .Where(id => id > 0)
            .ToArray();

        if (ids.Length == 0)
        {
            return;
        }

        const string stockSql = """
            SELECT
                i.id AS InsumoId,
                i.codigo AS Codigo,
                i.nombre AS Nombre,
                i.stock_minimo AS StockMinimo,
                ISNULL(s.cantidad_actual, 0) AS CantidadActual
            FROM inventario.insumo i
            LEFT JOIN inventario.stock_insumo s ON s.insumo_id = i.id
            WHERE i.id IN @Ids
              AND i.activo = 1;
            """;

        const string ruleSql = """
            SELECT TOP 1 id
            FROM alertas.regla_alerta
            WHERE codigo = 'STOCK_BAJO'
              AND activa = 1;
            """;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var ruleId = await connection.ExecuteScalarAsync<long?>(
            new CommandDefinition(ruleSql, cancellationToken: cancellationToken));

        if (ruleId is null)
        {
            return;
        }

        var rows = await connection.QueryAsync<LowStockRow>(
            new CommandDefinition(stockSql, new { Ids = ids }, cancellationToken: cancellationToken));

        foreach (var row in rows)
        {
            var hasLowStock = row.CantidadActual <= row.StockMinimo;

            const string existingSql = """
                SELECT TOP 1
                    id AS Id,
                    estado AS Estado
                FROM alertas.alerta
                WHERE tipo_alerta = 'STOCK_BAJO'
                  AND entidad_origen = 'inventario.insumo'
                  AND entidad_origen_id = @InsumoId
                  AND estado IN ('PENDIENTE', 'LEIDA')
                ORDER BY generada_en DESC, id DESC;
                """;

            var existingAlert = await connection.QuerySingleOrDefaultAsync<ExistingAlertRow>(
                new CommandDefinition(existingSql, new { row.InsumoId }, cancellationToken: cancellationToken));

            if (hasLowStock)
            {
                var severidad = row.CantidadActual <= 0 ? "ALTA" : "MEDIA";
                var titulo = $"Stock bajo: {row.Codigo}";
                var mensaje =
                    $"El insumo {row.Codigo} - {row.Nombre} tiene stock {row.CantidadActual} y minimo {row.StockMinimo}.";

                if (existingAlert is null)
                {
                    const string insertAlertSql = """
                        INSERT INTO alertas.alerta
                        (
                            regla_alerta_id,
                            tipo_alerta,
                            severidad,
                            titulo,
                            mensaje,
                            modulo_origen,
                            entidad_origen,
                            entidad_origen_id,
                            estado,
                            generada_en
                        )
                        OUTPUT INSERTED.id
                        VALUES
                        (
                            @ReglaAlertaId,
                            'STOCK_BAJO',
                            @Severidad,
                            @Titulo,
                            @Mensaje,
                            'Inventario',
                            'inventario.insumo',
                            @EntidadOrigenId,
                            'PENDIENTE',
                            @GeneradaEn
                        );
                        """;

                    var alertId = await connection.ExecuteScalarAsync<long>(
                        new CommandDefinition(
                            insertAlertSql,
                            new
                            {
                                ReglaAlertaId = ruleId.Value,
                                Severidad = severidad,
                                Titulo = titulo,
                                Mensaje = mensaje,
                                EntidadOrigenId = row.InsumoId,
                                GeneradaEn = dateTimeProvider.Now
                            },
                            cancellationToken: cancellationToken));

                    const string destinatariosSql = """
                        INSERT INTO alertas.alerta_destinatario (alerta_id, rol_id)
                        SELECT @AlertaId, r.id
                        FROM seguridad.rol r
                        WHERE r.codigo IN ('ADMIN', 'LOGISTICA');
                        """;

                    await connection.ExecuteAsync(
                        new CommandDefinition(
                            destinatariosSql,
                            new { AlertaId = alertId },
                            cancellationToken: cancellationToken));
                }
                else
                {
                    const string updateAlertSql = """
                        UPDATE alertas.alerta
                        SET severidad = @Severidad,
                            titulo = @Titulo,
                            mensaje = @Mensaje
                        WHERE id = @Id;
                        """;

                    await connection.ExecuteAsync(
                        new CommandDefinition(
                            updateAlertSql,
                            new
                            {
                                Id = existingAlert.Id,
                                Severidad = severidad,
                                Titulo = titulo,
                                Mensaje = mensaje
                            },
                            cancellationToken: cancellationToken));
                }
            }
            else if (existingAlert is not null)
            {
                const string closeAlertSql = """
                    UPDATE alertas.alerta
                    SET estado = 'CERRADA',
                        cerrada_en = @CerradaEn
                    WHERE id = @Id;
                    """;

                await connection.ExecuteAsync(
                    new CommandDefinition(
                        closeAlertSql,
                        new
                        {
                            Id = existingAlert.Id,
                            CerradaEn = dateTimeProvider.Now
                        },
                        cancellationToken: cancellationToken));

                const string historialSql = """
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
                        NULL,
                        @CambiadoEn
                    );
                    """;

                await connection.ExecuteAsync(
                    new CommandDefinition(
                        historialSql,
                        new
                        {
                            AlertaId = existingAlert.Id,
                            EstadoAnterior = existingAlert.Estado,
                            Comentario = $"Alerta cerrada automaticamente para {row.Codigo} al superar el stock minimo.",
                            CambiadoEn = dateTimeProvider.Now
                        },
                        cancellationToken: cancellationToken));
            }
        }
    }

    private sealed record ExistingAlertRow(long Id, string Estado);

    private sealed record LowStockRow(
        long InsumoId,
        string Codigo,
        string Nombre,
        decimal StockMinimo,
        decimal CantidadActual);
}
