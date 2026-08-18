using Dapper;
using ErpCurtiembre.Modules.Seguridad.Application.DTOs;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Domain.Entities;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence;
using ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;
using ErpCurtiembre.Shared.Persistence;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Repositories;

public sealed class SqlAuditoriaSeguridadRepository(
    ISqlConnectionFactory connectionFactory,
    SeguridadDbContext dbContext) : IAuditoriaSeguridadRepository
{
    public async Task RegisterAsync(AuditoriaSeguridadEvent auditoriaEvent, CancellationToken cancellationToken)
    {
        var entity = new AuditoriaSeguridadWriteModel
        {
            UsuarioAfectadoId = auditoriaEvent.UsuarioAfectadoId,
            UsuarioAccionId = auditoriaEvent.UsuarioAccionId,
            Evento = auditoriaEvent.Evento,
            Descripcion = auditoriaEvent.Descripcion,
            IpOrigen = auditoriaEvent.IpOrigen
        };

        dbContext.AuditoriasSeguridad.Add(entity);
        await dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<AuditoriaSeguridadItemDto>> ListAsync(AuditSecurityFiltersDto filters, CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT
                a.id AS Id,
                a.usuario_afectado_id AS UsuarioAfectadoId,
                CASE WHEN ua.id IS NULL THEN NULL ELSE CONCAT(ua.nombres, ' ', ua.apellidos) END AS UsuarioAfectado,
                a.usuario_accion_id AS UsuarioAccionId,
                CASE WHEN ux.id IS NULL THEN NULL ELSE CONCAT(ux.nombres, ' ', ux.apellidos) END AS UsuarioAccion,
                a.evento AS Evento,
                a.descripcion AS Descripcion,
                a.ip_origen AS IpOrigen,
                a.creado_en AS CreadoEn
            FROM seguridad.auditoria_seguridad a
            LEFT JOIN seguridad.usuario ua ON ua.id = a.usuario_afectado_id
            LEFT JOIN seguridad.usuario ux ON ux.id = a.usuario_accion_id
            WHERE (@UsuarioAfectadoId IS NULL OR a.usuario_afectado_id = @UsuarioAfectadoId)
              AND (@UsuarioAccionId IS NULL OR a.usuario_accion_id = @UsuarioAccionId)
              AND (@Evento IS NULL OR a.evento = @Evento)
            ORDER BY a.id DESC
            OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
            """;

        var normalizedPage = filters.Page <= 0 ? 1 : filters.Page;
        var normalizedPageSize = filters.PageSize <= 0 ? 50 : filters.PageSize;

        using var connection = await connectionFactory.CreateOpenConnectionAsync(cancellationToken);
        var items = await connection.QueryAsync<AuditoriaSeguridadItemDto>(
            new CommandDefinition(
                sql,
                new
                {
                    filters.UsuarioAfectadoId,
                    filters.UsuarioAccionId,
                    filters.Evento,
                    Offset = (normalizedPage - 1) * normalizedPageSize,
                    PageSize = normalizedPageSize
                },
                cancellationToken: cancellationToken));

        return items.ToArray();
    }
}
