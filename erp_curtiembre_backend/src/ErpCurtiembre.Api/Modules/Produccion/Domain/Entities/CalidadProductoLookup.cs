namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed record CalidadProductoLookup(
    long Id,
    string Codigo,
    string Nombre,
    bool Activo);
