namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class EntradaInventarioWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string TipoEntrada { get; set; } = string.Empty;

    public long? OrdenCompraId { get; set; }

    public DateTime FechaEntrada { get; set; }

    public string? DocumentoSoporte { get; set; }

    public string? Observacion { get; set; }

    public string Estado { get; set; } = string.Empty;

    public long? CreadoPorUsuarioId { get; set; }

    public DateTime CreadoEn { get; set; }
}
