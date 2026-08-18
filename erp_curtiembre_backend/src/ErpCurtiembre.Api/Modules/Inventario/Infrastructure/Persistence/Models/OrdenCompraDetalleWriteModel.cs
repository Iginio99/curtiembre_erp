namespace ErpCurtiembre.Modules.Inventario.Infrastructure.Persistence.Models;

public sealed class OrdenCompraDetalleWriteModel
{
    public long Id { get; set; }

    public long OrdenCompraId { get; set; }

    public long InsumoId { get; set; }

    public decimal CantidadSolicitada { get; set; }

    public decimal CantidadRecibida { get; set; }

    public decimal? CostoUnitarioEstimado { get; set; }

    public string? Observacion { get; set; }
}
