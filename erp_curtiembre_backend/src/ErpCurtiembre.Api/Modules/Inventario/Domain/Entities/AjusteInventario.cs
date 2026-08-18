namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed class AjusteInventario
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string TipoAjuste { get; init; } = string.Empty;

    public DateTime FechaAjuste { get; init; }

    public string Motivo { get; init; } = string.Empty;

    public string? Observacion { get; init; }

    public long UsuarioResponsableId { get; init; }

    public int TotalItems { get; init; }

    public decimal CantidadTotal { get; init; }

    public decimal MontoTotal { get; init; }
}
