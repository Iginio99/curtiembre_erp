using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record OrdenCompraDetalleRequestDto(
    [property: Range(1, long.MaxValue)] long InsumoId,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal CantidadSolicitada,
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal? CostoUnitarioEstimado,
    [property: StringLength(300)] string? Observacion = null);

public sealed record CreateOrdenCompraRequestDto(
    [property: Range(1, long.MaxValue)] long ProveedorId,
    DateTime FechaEmision,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<OrdenCompraDetalleRequestDto> Detalles);

public sealed record OrdenCompraDecisionRequestDto(
    [property: Required]
    [property: StringLength(500)]
    string Motivo);

public sealed record OrdenCompraFiltersDto(
    string? Texto = null,
    long? ProveedorId = null,
    string? Estado = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record OrdenCompraListItemDto(
    long Id,
    string Codigo,
    long ProveedorId,
    string ProveedorRazonSocial,
    DateTime FechaEmision,
    DateTime? FechaAprobacion,
    long? AprobadoPorUsuarioId,
    string Estado,
    string? Observacion,
    string? Motivo,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId,
    DateTime? ActualizadoEn,
    long? ActualizadoPorUsuarioId,
    int TotalItems,
    decimal CantidadTotalSolicitada,
    decimal CantidadTotalRecibida,
    decimal MontoTotalEstimado);

public sealed record OrdenCompraDetalleDto(
    long Id,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    decimal CantidadSolicitada,
    decimal CantidadRecibida,
    decimal SaldoPendiente,
    decimal? CostoUnitarioEstimado,
    decimal MontoEstimado,
    string? Observacion);

public sealed record OrdenCompraDetailDto(
    long Id,
    string Codigo,
    long ProveedorId,
    string ProveedorRazonSocial,
    DateTime FechaEmision,
    DateTime? FechaAprobacion,
    long? AprobadoPorUsuarioId,
    string Estado,
    string? Observacion,
    string? Motivo,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId,
    DateTime? ActualizadoEn,
    long? ActualizadoPorUsuarioId,
    IReadOnlyCollection<OrdenCompraDetalleDto> Detalles);
