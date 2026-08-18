namespace ErpCurtiembre.Modules.Configuracion.Domain.Entities;

public sealed class FormulaVersion
{
    public long Id { get; init; }

    public long FormulaId { get; init; }

    public string FormulaCodigo { get; init; } = string.Empty;

    public string FormulaNombre { get; init; } = string.Empty;

    public int NumeroVersion { get; init; }

    public DateTime FechaInicioVigencia { get; init; }

    public DateTime? FechaFinVigencia { get; init; }

    public bool Vigente { get; init; }

    public string? Observacion { get; init; }

    public DateTime CreadoEn { get; init; }

    public long? CreadoPorUsuarioId { get; init; }
}
