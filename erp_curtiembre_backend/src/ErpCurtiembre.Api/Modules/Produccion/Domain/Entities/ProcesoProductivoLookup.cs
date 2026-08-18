namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class ProcesoProductivoLookup
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Nombre { get; init; } = string.Empty;

    public int OrdenSecuencia { get; init; }

    public bool EsObligatorio { get; init; }

    public bool Activo { get; init; }
}
