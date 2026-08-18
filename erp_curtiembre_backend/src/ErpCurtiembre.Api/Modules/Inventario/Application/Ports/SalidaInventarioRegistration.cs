namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public sealed record SalidaInventarioRegistration(
    string Codigo,
    string TipoSalida,
    long? OrdenProduccionId,
    long? OrdenProcesoId,
    DateTime FechaSalida,
    string Motivo,
    string? Observacion,
    long ActorId,
    IReadOnlyCollection<SalidaInventarioRegistrationDetail> Detalles);

public sealed record SalidaInventarioRegistrationDetail(
    long InsumoId,
    decimal Cantidad,
    string? Observacion);
