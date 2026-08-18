using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record RegistrarAjusteDetalleRequestDto(
    [property: Range(1, long.MaxValue)] long InsumoId,
    [property: Range(typeof(decimal), "0.0001", "999999999999999.9999")] decimal Cantidad,
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal? CostoUnitario = null);

public sealed record RegistrarAjusteInventarioRequestDto(
    [property: Required]
    [property: StringLength(200)]
    string Motivo,
    [property: StringLength(500)] string? Observacion,
    [property: MinLength(1)] IReadOnlyCollection<RegistrarAjusteDetalleRequestDto> Detalles);

public sealed record AjusteInventarioFiltersDto(
    string? Texto = null,
    string? TipoAjuste = null,
    DateTime? FechaDesde = null,
    DateTime? FechaHasta = null);

public sealed record AjusteInventarioListItemDto(
    long Id,
    string Codigo,
    string TipoAjuste,
    DateTime FechaAjuste,
    string Motivo,
    string? Observacion,
    long UsuarioResponsableId,
    int TotalItems,
    decimal CantidadTotal,
    decimal MontoTotal);

public sealed record AjusteInventarioDetalleDto(
    long Id,
    long InsumoId,
    string InsumoCodigo,
    string InsumoNombre,
    decimal Cantidad,
    decimal? CostoUnitario,
    decimal CostoTotal,
    decimal StockActual,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre);

public sealed record AjusteInventarioDetailDto(
    long Id,
    string Codigo,
    string TipoAjuste,
    DateTime FechaAjuste,
    string Motivo,
    string? Observacion,
    long UsuarioResponsableId,
    IReadOnlyCollection<AjusteInventarioDetalleDto> Detalles);
