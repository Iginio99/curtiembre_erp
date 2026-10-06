namespace ErpCurtiembre.Modules.Configuracion.Domain.Entities;

public sealed class ProductoCatalogo
{
    public long Id { get; init; }
    public string Codigo { get; init; } = string.Empty;
    public string Tipo { get; init; } = string.Empty;
    public string Nombre { get; init; } = string.Empty;
    public string? Color { get; init; }
    public bool Activo { get; init; }
    public DateTime CreadoEn { get; init; }
}
