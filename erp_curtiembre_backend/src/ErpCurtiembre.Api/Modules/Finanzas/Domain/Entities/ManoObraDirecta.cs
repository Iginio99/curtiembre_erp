namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class ManoObraDirecta
{
    public long Id { get; init; }

    public long OrdenProduccionId { get; init; }

    public string OrdenProduccionCodigo { get; init; } = string.Empty;

    public long OrdenProcesoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public decimal Monto { get; init; }

    public string? Descripcion { get; init; }

    public DateTime RegistradoEn { get; init; }

    public long? RegistradoPorUsuarioId { get; init; }
}
