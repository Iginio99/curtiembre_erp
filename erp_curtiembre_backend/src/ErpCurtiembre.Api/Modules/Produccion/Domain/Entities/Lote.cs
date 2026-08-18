namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class Lote
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public long ClienteId { get; init; }

    public string ClienteRazonSocial { get; init; } = string.Empty;

    public long TipoPielId { get; init; }

    public string TipoPielCodigo { get; init; } = string.Empty;

    public string TipoPielNombre { get; init; } = string.Empty;

    public DateTime FechaIngreso { get; init; }

    public decimal CantidadPielesInicial { get; init; }

    public decimal CantidadPielesUtilizada { get; init; }

    public decimal CantidadPielesDisponible { get; init; }

    public decimal CantidadLadosCalculada { get; init; }

    public bool ClienteTraeLote { get; init; }

    public decimal CostoPielesTotal { get; init; }

    public string? Observacion { get; init; }

    public string Estado { get; init; } = string.Empty;

    public DateTime CreadoEn { get; init; }

    public long? CreadoPorUsuarioId { get; init; }
}
