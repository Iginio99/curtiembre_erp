namespace ErpCurtiembre.Modules.Auditoria.Domain.Entities;

public sealed record RegistroAuditoria(
    Guid Id,
    string Modulo,
    string Accion,
    string Usuario,
    DateTimeOffset Fecha);
