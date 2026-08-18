namespace ErpCurtiembre.Modules.Configuracion.Domain.Entities;

public sealed class FormulaDetalle
{
    public long Id { get; init; }

    public long FormulaVersionId { get; init; }

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public decimal Porcentaje { get; init; }

    public string? Observacion { get; init; }

    public bool Activo { get; init; }
}
