using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record CreateInsumoRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(150)] string Nombre,
    [property: Required, StringLength(40)] string TipoBien,
    [property: StringLength(150)] string? Presentacion,
    [property: Range(1, long.MaxValue)] long UnidadMedidaId,
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal StockMinimo,
    bool RequiereLote);

public sealed record UpdateInsumoRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(150)] string Nombre,
    [property: Required, StringLength(40)] string TipoBien,
    [property: StringLength(150)] string? Presentacion,
    [property: Range(1, long.MaxValue)] long UnidadMedidaId,
    [property: Range(typeof(decimal), "0", "999999999999999.9999")] decimal StockMinimo,
    bool RequiereLote);

public sealed record InsumoFiltersDto(
    string? Texto = null,
    string? TipoBien = null,
    long? UnidadMedidaId = null,
    bool? Activo = null,
    bool? StockBajo = null);

public sealed record InsumoListItemDto(
    long Id,
    string Codigo,
    string Nombre,
    string TipoBien,
    string? Presentacion,
    long UnidadMedidaId,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    decimal StockMinimo,
    decimal CostoPromedioActual,
    decimal StockActual,
    bool RequiereLote,
    bool Activo,
    DateTime CreadoEn,
    DateTime? ActualizadoEn);

public sealed record InsumoDetailDto(
    long Id,
    string Codigo,
    string Nombre,
    string TipoBien,
    string? Presentacion,
    long UnidadMedidaId,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    decimal StockMinimo,
    decimal CostoPromedioActual,
    decimal StockActual,
    bool RequiereLote,
    bool Activo,
    DateTime CreadoEn,
    long? CreadoPorUsuarioId,
    DateTime? ActualizadoEn,
    long? ActualizadoPorUsuarioId);

public sealed record InsumoLookupDto(
    long Id,
    string Codigo,
    string Nombre,
    string TipoBien,
    string UnidadMedidaCodigo,
    string UnidadMedidaNombre,
    decimal StockActual);
