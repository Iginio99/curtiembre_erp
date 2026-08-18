using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record CrearSolicitudInsumoDetalleRequestDto(
    [property: Range(1, long.MaxValue)] long InsumoId,
    [property: Range(typeof(decimal), "0.01", "999999999999999.99")] decimal Cantidad,
    [property: StringLength(300)] string? Observacion = null);

public sealed record CrearSolicitudInsumoRequestDto(
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<CrearSolicitudInsumoDetalleRequestDto> Detalles);

public sealed record EntregarSolicitudInsumoRequestDto(
    [property: StringLength(150)] string? Motivo,
    [property: StringLength(500)] string? Observacion);

public sealed record SolicitudInsumoListItemDto(
    long Id,
    string Codigo,
    long OrdenProduccionId,
    string OrdenCodigo,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    string Estado,
    string? Observacion,
    DateTime SolicitadoEn,
    long SolicitadoPorUsuarioId,
    string SolicitadoPorNombre,
    int TotalItems,
    decimal CantidadTotal);

public sealed record SolicitudInsumoDetailDto(
    long Id,
    string Codigo,
    long OrdenProduccionId,
    string OrdenCodigo,
    long OrdenProcesoId,
    string ProcesoCodigo,
    string ProcesoNombre,
    string Estado,
    string? Observacion,
    DateTime SolicitadoEn,
    long SolicitadoPorUsuarioId,
    string SolicitadoPorNombre,
    IReadOnlyCollection<SolicitudInsumoDetalleDto> Detalles);

public sealed record SolicitudInsumoDetalleDto(
    long Id,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    decimal CantidadSolicitada,
    string? Observacion);
