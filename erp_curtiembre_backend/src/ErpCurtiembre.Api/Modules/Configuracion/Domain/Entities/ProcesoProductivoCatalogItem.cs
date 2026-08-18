namespace ErpCurtiembre.Modules.Configuracion.Domain.Entities;

public sealed class ProcesoProductivoCatalogItem
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Nombre { get; init; } = string.Empty;

    public int OrdenSecuencia { get; init; }
}
