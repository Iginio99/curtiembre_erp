namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class EntradaInventarioDetalleWriteModel
{
    public long Id { get; set; }

    public long EntradaInventarioId { get; set; }

    public long? OrdenCompraDetalleId { get; set; }

    public long InsumoId { get; set; }

    public decimal Cantidad { get; set; }

    public decimal CostoUnitario { get; set; }

    public string? Observacion { get; set; }
}
