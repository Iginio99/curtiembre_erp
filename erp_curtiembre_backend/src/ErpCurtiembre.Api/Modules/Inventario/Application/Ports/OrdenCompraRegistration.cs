namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public sealed record OrdenCompraRegistration(
    string Codigo,
    long ProveedorId,
    DateTime FechaEmision,
    string? Observacion,
    long ActorId,
    IReadOnlyCollection<OrdenCompraRegistrationDetail> Detalles);

public sealed record OrdenCompraRegistrationDetail(
    long InsumoId,
    decimal CantidadSolicitada,
    decimal? CostoUnitarioEstimado,
    string? Observacion);
