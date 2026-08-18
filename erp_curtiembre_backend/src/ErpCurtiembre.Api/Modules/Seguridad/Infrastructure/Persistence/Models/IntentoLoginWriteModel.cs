namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;

public sealed class IntentoLoginWriteModel
{
    public long Id { get; set; }

    public string UsuarioLogin { get; set; } = string.Empty;

    public long? UsuarioId { get; set; }

    public bool FueExitoso { get; set; }

    public string? IpOrigen { get; set; }

    public string? Mensaje { get; set; }

    public DateTime CreadoEn { get; set; }
}
