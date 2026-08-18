namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class EntradaInventario
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string TipoEntrada { get; init; } = string.Empty;

    public long? OrdenCompraId { get; init; }

    public DateTime FechaEntrada { get; init; }

    public string? DocumentoSoporte { get; init; }

    public string? Observacion { get; init; }

    public string Estado { get; init; } = string.Empty;

    public long? CreadoPorUsuarioId { get; init; }

    public DateTime CreadoEn { get; init; }
}
