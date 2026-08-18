using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record RegistrarSalidaDetalleRequestDto(
    [property: Range(1, long.MaxValue)] long InsumoId,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal Cantidad,
    [property: StringLength(300)] string? Observacion = null);

public sealed record RegistrarSalidaGeneralRequestDto(
    [property: Required]
    [property: StringLength(150)]
    string Motivo,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<RegistrarSalidaDetalleRequestDto> Detalles);

public sealed record RegistrarSalidaProcesoRequestDto(
    [property: Range(1, long.MaxValue)] long OrdenProduccionId,
    long? OrdenProcesoId,
    [property: StringLength(150)] string? Motivo,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<RegistrarSalidaDetalleRequestDto> Detalles);

public sealed record RegistrarDevolucionProveedorRequestDto(
    [property: Required]
    [property: StringLength(150)]
    string Motivo,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<RegistrarSalidaDetalleRequestDto> Detalles);

public sealed record RegistrarAjusteNegativoRequestDto(
    [property: Required]
    [property: StringLength(150)]
    string Motivo,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<RegistrarSalidaDetalleRequestDto> Detalles);

public sealed record SalidaInventarioFiltersDto(
    string? Texto = null,
    string? TipoSalida = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record SalidaInventarioListItemDto(
    long Id,
    string Codigo,
    string TipoSalida,
    long? OrdenProduccionId,
    long? OrdenProcesoId,
    DateTime FechaSalida,
    string? Motivo,
    string? Observacion,
    string Estado,
    long? CreadoPorUsuarioId,
    DateTime CreadoEn,
    int TotalItems,
    decimal CantidadTotal,
    decimal MontoTotal);

public sealed record SalidaInventarioDetalleDto(
    long Id,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal Cantidad,
    decimal CostoUnitario,
    decimal CostoTotal,
    decimal StockActual,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    string? Observacion);

public sealed record SalidaInventarioDetailDto(
    long Id,
    string Codigo,
    string TipoSalida,
    long? OrdenProduccionId,
    long? OrdenProcesoId,
    DateTime FechaSalida,
    string? Motivo,
    string? Observacion,
    string Estado,
    long? CreadoPorUsuarioId,
    DateTime CreadoEn,
    IReadOnlyCollection<SalidaInventarioDetalleDto> Detalles);
