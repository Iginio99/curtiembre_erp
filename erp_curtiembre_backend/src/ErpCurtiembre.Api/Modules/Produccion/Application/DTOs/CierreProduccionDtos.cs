using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record RegistrarMermaProcesoRequestDto(
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal CantidadPerdida,
    [property: StringLength(300)] string? Motivo,
    [property: StringLength(500)] string? Observacion);

public sealed record RegistrarCalidadFinalRequestDto(
    [property: Range(1, long.MaxValue)] long CalidadProductoId,
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
    string Estado,
    string? Observacion);

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
    string Estado,
    string? Observacion);
