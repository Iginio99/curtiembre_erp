namespace ErpCurtiembre.Modules.Inventario.Domain.Entities;

public sealed record UnidadMedidaLookup(
    long Id,
    string Codigo,
    string Nombre,
    bool PermiteDecimales,
    bool Activo);
