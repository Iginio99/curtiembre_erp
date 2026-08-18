namespace ErpCurtiembre.Modules.Finanzas.Infrastructure.Persistence.Models;

public sealed class ActivoDepreciableWriteModel
{
    public long Id { get; set; }

    public string Codigo { get; set; } = string.Empty;

    public string Nombre { get; set; } = string.Empty;

    public decimal ValorCompra { get; set; }

    public DateTime FechaCompra { get; set; }

    public int VidaUtilMeses { get; set; }

    public decimal ValorResidual { get; set; }

    public bool Activo { get; set; }

    public DateTime CreadoEn { get; set; }
}
