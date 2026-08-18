namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class InsumoWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public string TipoBien { get; set; } = string.Empty;

    public string? Presentacion { get; set; }

    public long UnidadMedidaId { get; set; }

    public decimal StockMinimo { get; set; }

    public decimal CostoPromedioActual { get; set; }

    public bool RequiereLote { get; set; }

    public bool Activo { get; set; }

    public DateTime CreadoEn { get; set; }

    public long? CreadoPorUsuarioId { get; set; }

    public DateTime? ActualizadoEn { get; set; }

    public long? ActualizadoPorUsuarioId { get; set; }
}
