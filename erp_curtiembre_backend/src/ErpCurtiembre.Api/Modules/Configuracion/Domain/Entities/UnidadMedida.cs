namespace ErpCurtiembre.Modules.Configuracion.Domain.Entities;

public sealed class UnidadMedida
{
    public long Id { get; init; }

    public string Codigo { get; init; } = string.Empty;

    public string Nombre { get; init; } = string.Empty;

    public bool PermiteDecimales { get; init; }

    public bool Activo { get; init; }

    public DateTime CreadoEn { get; init; }
}
