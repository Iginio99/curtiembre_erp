namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class AjusteInventarioWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string TipoAjuste { get; set; } = string.Empty;

    public DateTime FechaAjuste { get; set; }

    public string Motivo { get; set; } = string.Empty;

    public string? Observacion { get; set; }

    public long UsuarioResponsableId { get; set; }
}
