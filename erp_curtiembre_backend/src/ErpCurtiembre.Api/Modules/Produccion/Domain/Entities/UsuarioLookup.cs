namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed class UsuarioLookup
{
    public long Id { get; init; }

    public string UserName { get; init; } = string.Empty;

    public string NombreCompleto { get; init; } = string.Empty;
}
