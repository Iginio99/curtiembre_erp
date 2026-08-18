namespace ErpCurtiembre.Modules.Produccion.Domain.Entities;

public sealed record TipoPielLookup(
    long Id,
    string Codigo,
    string Nombre,
    bool Activo);
