namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Persistence.Models;

public sealed class SesionUsuarioWriteModel
{
    public long Id { get; set; }

    public long UsuarioId { get; set; }

    public string TokenHash { get; set; } = string.Empty;

    public string? IpOrigen { get; set; }

    public string? UserAgent { get; set; }

    public DateTime InicioEn { get; set; }

    public DateTime ExpiraEn { get; set; }

    public DateTime? CerradoEn { get; set; }

    public string? MotivoCierre { get; set; }

    public bool Activa { get; set; }
}
