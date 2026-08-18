using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Configuracion.Application.DTOs;

public sealed record CreateAreaRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(100)] string Nombre,
    [property: StringLength(250)] string? Descripcion);

public sealed record UpdateAreaRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(100)] string Nombre,
    [property: StringLength(250)] string? Descripcion);

public sealed record AreaFiltersDto(
    string? Texto = null,
    bool? Activo = null);

public sealed record AreaListItemDto(
    long Id,
    string Codigo,
    string Nombre,
    string? Descripcion,
    bool Activo,
    DateTime CreadoEn,
    DateTime? ActualizadoEn);

public sealed record AreaDetailDto(
    long Id,
    string Codigo,
    string Nombre,
    string? Descripcion,
    bool Activo,
    DateTime CreadoEn,
    DateTime? ActualizadoEn);
