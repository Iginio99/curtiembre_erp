namespace ErpCurtiembre.Modules.Configuracion.Domain.Entities;

public sealed class TipoPiel
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Nombre { get; init; } = string.Empty;

    public string? Descripcion { get; init; }

    public bool Activo { get; init; }

    public DateTime CreadoEn { get; init; }
}
