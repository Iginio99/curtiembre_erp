namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface IProduccionInventarioGateway
{
    Task<InventoryProcessConsumptionResult> RegisterProcessConsumptionAsync(
        long ordenProduccionId,
        long ordenProcesoId,
        string motivo,
        string? observacion,
        IReadOnlyCollection<InventoryProcessConsumptionDetailRequest> detalles,
        long actorId,
        CancellationToken cancellationToken);
}

public sealed record InventoryProcessConsumptionDetailRequest(
    long InsumoId,
    decimal Cantidad,
    string? Observacion);

public sealed record InventoryProcessConsumptionDetailResult(
    long SalidaInventarioDetalleId,
    long InsumoId,
    decimal Cantidad,
    decimal CostoUnitario,
    decimal CostoTotal);

public sealed record InventoryProcessConsumptionResult(
    bool Success,
    string Message,
    string? ErrorCode,
    long? SalidaInventarioId,
    IReadOnlyCollection<InventoryProcessConsumptionDetailResult> Details);
