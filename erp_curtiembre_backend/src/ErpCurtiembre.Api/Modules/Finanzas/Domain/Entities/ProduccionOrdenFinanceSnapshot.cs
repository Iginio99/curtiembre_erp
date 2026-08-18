namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class ProduccionOrdenFinanceSnapshot
{
    public long OrdenProduccionId { get; init; }

    public string OrdenProduccionCodigo { get; init; } = string.Empty;

    public long LoteId { get; init; }

    public decimal CantidadPieles { get; init; }

    public string OrdenEstado { get; init; } = string.Empty;

    public bool ClienteTraeLote { get; init; }

    public decimal CostoPielesTotal { get; init; }

    public DateTime? FechaFinReal { get; init; }

    public decimal? PielesBuenasFinales { get; init; }
}
