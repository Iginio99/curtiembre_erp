namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public sealed record StockInitialRegistration(
    string Codigo,
    DateTime FechaEntrada,
    string? DocumentoSoporte,
    string? Observacion,
    long ActorId,
    IReadOnlyCollection<StockInitialRegistrationDetail> Detalles);

public sealed record StockInitialRegistrationDetail(
    long InsumoId,
    decimal Cantidad,
    decimal CostoUnitario,
    string? Observacion);
