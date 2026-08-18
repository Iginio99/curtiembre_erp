namespace ErpCurtiembre.Modules.Seguridad.Application.DTOs;

public sealed record AuditSecurityFiltersDto(
    long? UsuarioAfectadoId = null,
    long? UsuarioAccionId = null,
    string? Evento = null,
    int Page = 1,
    int PageSize = 50);

public sealed record AuditoriaSeguridadItemDto(
    long Id,
    long? UsuarioAfectadoId,
    string? UsuarioAfectado,
    long? UsuarioAccionId,
    string? UsuarioAccion,
    string Evento,
    string? Descripcion,
    string? IpOrigen,
    DateTime CreadoEn);
