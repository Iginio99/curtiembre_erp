namespace ErpCurtiembre.Modules.Seguridad.Domain.Entities;

public sealed class AuditoriaSeguridadEvent
{
    public long? UsuarioAfectadoId { get; init; }

    public long? UsuarioAccionId { get; init; }

    public string Evento { get; init; } = string.Empty;

    public string? Descripcion { get; init; }

    public string? IpOrigen { get; init; }
}
