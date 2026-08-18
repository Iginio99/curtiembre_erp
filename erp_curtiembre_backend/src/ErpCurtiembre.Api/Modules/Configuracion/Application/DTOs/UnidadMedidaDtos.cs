using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Configuracion.Application.DTOs;

public sealed record CreateUnidadMedidaRequestDto(
    [property: Required, StringLength(20)] string Codigo,
    [property: Required, StringLength(80)] string Nombre,
    bool PermiteDecimales);

public sealed record UpdateUnidadMedidaRequestDto(
    [property: Required, StringLength(20)] string Codigo,
    [property: Required, StringLength(80)] string Nombre,
    bool PermiteDecimales);

public sealed record UnidadMedidaFiltersDto(
    string? Texto = null,
    bool? Activo = null,
    bool? PermiteDecimales = null);

public sealed record UnidadMedidaListItemDto(
    long Id,
    string Codigo,
    string Nombre,
    bool PermiteDecimales,
    bool Activo,
    DateTime CreadoEn);

public sealed record UnidadMedidaDetailDto(
    long Id,
    string Codigo,
    string Nombre,
    bool PermiteDecimales,
    bool Activo,
    DateTime CreadoEn);
