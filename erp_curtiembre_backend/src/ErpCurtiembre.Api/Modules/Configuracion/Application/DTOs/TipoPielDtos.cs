using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Configuracion.Application.DTOs;

public sealed record CreateTipoPielRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(120)] string Nombre,
    [property: StringLength(250)] string? Descripcion);

public sealed record UpdateTipoPielRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(120)] string Nombre,
    [property: StringLength(250)] string? Descripcion);

public sealed record TipoPielFiltersDto(
    string? Texto = null,
    bool? Activo = null);

public sealed record TipoPielListItemDto(
    long Id,
    string Codigo,
    string Nombre,
    string? Descripcion,
    bool Activo,
    DateTime CreadoEn);

public sealed record TipoPielDetailDto(
    long Id,
    string Codigo,
    string Nombre,
    string? Descripcion,
    bool Activo,
    DateTime CreadoEn);
