namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class FormulaConsumptionDetail
{
    public long ProcesoProductivoId { get; init; }

    public string ProcesoCodigo { get; init; } = string.Empty;

    public string ProcesoNombre { get; init; } = string.Empty;

    public long FormulaId { get; init; }

    public string FormulaCodigo { get; init; } = string.Empty;

    public long FormulaVersionId { get; init; }

    public int NumeroVersion { get; init; }

    public long InsumoId { get; init; }

    public string InsumoCodigo { get; init; } = string.Empty;

    public string InsumoNombre { get; init; } = string.Empty;

    public decimal Porcentaje { get; init; }
}
