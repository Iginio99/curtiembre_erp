namespace ErpCurtiembre.Modules.Auditoria.Application.DTOs;

public sealed record RegistroAuditoriaDto(
    Guid Id,
    string Modulo,
    string Accion,
    string Usuario,
    DateTimeOffset Fecha);
