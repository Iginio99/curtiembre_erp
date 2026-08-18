namespace ErpCurtiembre.Modules.Finanzas.Domain.Entities;

public sealed class ActivoDepreciable
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Nombre { get; init; } = string.Empty;

    public decimal ValorCompra { get; init; }

    public DateTime FechaCompra { get; init; }

    public int VidaUtilMeses { get; init; }

    public decimal ValorResidual { get; init; }

    public bool Activo { get; init; }

    public DateTime CreadoEn { get; init; }
}
