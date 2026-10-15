using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record RegistrarMermaProcesoRequestDto(
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal CantidadPerdida,
    [property: StringLength(300)] string? Motivo,
    [property: StringLength(500)] string? Observacion);

public sealed record RegistrarCalidadFinalRequestDto(
    [property: Range(1, long.MaxValue)] long CalidadProductoId,
    [property: Range(typeof(decimal), "0", "999999999999999")] decimal CantidadLadosA,
    [property: Range(typeof(decimal), "0", "999999999999999")] decimal CantidadLadosB,
    [property: Range(typeof(decimal), "0", "999999999999999")] decimal CantidadLadosC,
    [property: Range(typeof(decimal), "0", "999999999999999")] decimal CantidadLadosMerma,
    [property: StringLength(30)] string? Resultado,
    [property: StringLength(800)] string? Observacion);

public sealed record FinalizarOrdenProduccionRequestDto(
    [property: Range(typeof(decimal), "0", "999999999999999.99")] decimal CantidadLados,
    [property: StringLength(500)] string? Observacion);

public sealed record MermaProcesoDto(
    long Id,
    long OrdenProduccionId,
    long OrdenProcesoId,
    long ProcesoProductivoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    decimal CantidadPerdida,
    string? Motivo,
    string? Observacion,
    DateTime RegistradoEn,
    long? RegistradoPorUsuarioId,
    string? RegistradoPorNombre);

public sealed record ControlCalidadDto(
    long Id,
    long OrdenProduccionId,
    long? ProductoTerminadoId,
    long CalidadProductoId,
    string CalidadCodigo,
    string CalidadNombre,
    decimal CantidadLadosA,
    decimal CantidadLadosB,
    decimal CantidadLadosC,
    decimal CantidadLadosMerma,
    string Resultado,
    string? Observacion,
    DateTime EvaluadoEn,
    long? EvaluadoPorUsuarioId,
    string? EvaluadoPorNombre);

public sealed record ProductoTerminadoListItemDto(
    long Id,
    string Codigo,
    long OrdenProduccionId,
    string OrdenCodigo,
    long CalidadProductoId,
    string CalidadCodigo,
    string CalidadNombre,
    DateTime FechaIngreso,
    decimal CantidadPielesBuenas,
    decimal CantidadLadosCalculada,
    decimal CantidadLadosA,
    decimal CantidadLadosB,
    decimal CantidadLadosC,
    decimal CantidadLadosMerma,
    string Estado,
    string? Observacion,
    long? OrdenProductoId,
    string? ProductoNombre,
    string? ProductoColor,
    bool EsProductoIndividual,
    string? ClienteNombre = null,
    decimal CantidadLadosProgramados = 0,
    decimal CantidadLadosEntregados = 0,
    decimal CantidadLadosPendientes = 0,
    DateTime? FechaOrden = null,
    DateTime? FechaTerminacionOrden = null);

public sealed record EntregaProductoTerminadoHistorialDto(
    long Id,
    string Codigo,
    DateTime Fecha,
    string ClienteNombre,
    string? Responsable,
    string? RecibidoPor,
    string? Observacion,
    long ProductoTerminadoId,
    string Producto,
    decimal CantidadLados,
    string Estado);

public sealed record RegistrarEntregaProductoTerminadoDetalleDto(
    [property: Range(1, long.MaxValue)] long ProductoTerminadoId,
    [property: Range(typeof(decimal), "0.0001", "999999999999999")] decimal CantidadLados);

public sealed record RegistrarEntregaProductosTerminadosRequestDto(
    [property: Range(1, long.MaxValue)] long OrdenProduccionId,
    DateTime? FechaEntrega,
    [property: StringLength(500)] string? Observacion,
    [property: StringLength(150)] string? RecibidoPor,
    [property: Required, MinLength(1)] IReadOnlyCollection<RegistrarEntregaProductoTerminadoDetalleDto> Detalles);

public sealed record ProductoTerminadoDetailDto(
    long Id,
    string Codigo,
    long OrdenProduccionId,
    string OrdenCodigo,
    long CalidadProductoId,
    string CalidadCodigo,
    string CalidadNombre,
    DateTime FechaIngreso,
    decimal CantidadPielesBuenas,
    decimal CantidadLadosCalculada,
    decimal CantidadLadosA,
    decimal CantidadLadosB,
    decimal CantidadLadosC,
    decimal CantidadLadosMerma,
    string Estado,
    string? Observacion,
    long? OrdenProductoId,
    string? ProductoNombre,
    string? ProductoColor,
    bool EsProductoIndividual);
