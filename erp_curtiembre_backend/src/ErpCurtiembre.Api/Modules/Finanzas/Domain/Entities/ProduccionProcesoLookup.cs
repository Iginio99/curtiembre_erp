namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class ProduccionProcesoLookup
{
    public long OrdenProduccionId { get; init; }

    public string OrdenProduccionCodigo { get; init; } = string.Empty;

    public long OrdenProcesoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public string OrdenEstado { get; init; } = string.Empty;

    public string ProcesoEstado { get; init; } = string.Empty;
}
