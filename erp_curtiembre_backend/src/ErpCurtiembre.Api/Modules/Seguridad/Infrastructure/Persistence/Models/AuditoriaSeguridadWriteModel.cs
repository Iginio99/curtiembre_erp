namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;

public sealed class AuditoriaSeguridadWriteModel
{
    public long Id { get; set; }

    public long? UsuarioAfectadoId { get; set; }

    public long? UsuarioAccionId { get; set; }

    public string Evento { get; set; } = string.Empty;

    public string? Descripcion { get; set; }

    public string? IpOrigen { get; set; }

    public DateTime CreadoEn { get; set; }
}
