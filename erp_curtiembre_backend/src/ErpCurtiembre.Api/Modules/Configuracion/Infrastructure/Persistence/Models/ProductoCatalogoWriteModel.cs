namespace ErpCurtiembre.Modules.Configuracion.Infrastructure.Persistence.Models;

public sealed class ProductoCatalogoWriteModel
{
    public long Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Tipo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string? Color { get; set; }
    public bool Activo { get; set; }
    public DateTime CreadoEn { get; set; }
}
