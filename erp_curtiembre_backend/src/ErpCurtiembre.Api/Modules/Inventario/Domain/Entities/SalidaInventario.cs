namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class SalidaInventario
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string TipoSalida { get; init; } = string.Empty;

    public long? OrdenProduccionId { get; init; }

    public long? OrdenProcesoId { get; init; }

    public DateTime FechaSalida { get; init; }

    public string? Motivo { get; init; }

    public string? Observacion { get; init; }

    public string Estado { get; init; } = string.Empty;

    public long? CreadoPorUsuarioId { get; init; }

    public DateTime CreadoEn { get; init; }

    public int TotalItems { get; init; }

    public decimal CantidadTotal { get; init; }

    public decimal MontoTotal { get; init; }
}
