namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public sealed record PurchaseEntryRegistration(
    string Codigo,
    long OrdenCompraId,
    DateTime FechaEntrada,
    string DocumentoSoporte,
    string? Observacion,
    long ActorId,
    IReadOnlyCollection<PurchaseEntryRegistrationDetail> Detalles);

public sealed record PurchaseEntryRegistrationDetail(
    long OrdenCompraDetalleId,
    long InsumoId,
    decimal Cantidad,
    decimal CostoUnitario,
    string? Observacion);
