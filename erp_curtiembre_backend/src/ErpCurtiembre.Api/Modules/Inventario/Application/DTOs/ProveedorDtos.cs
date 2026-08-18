using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Inventario.Application.DTOs;

public sealed record CreateProveedorRequestDto(
    [property: Required, StringLength(20)] string RucDocumento,
    [property: Required, StringLength(180)] string RazonSocial,
    [property: StringLength(250)] string? Direccion,
    [property: StringLength(30)] string? Telefono,
    [property: StringLength(150)] string? Correo,
    [property: StringLength(150)] string? Contacto);

public sealed record UpdateProveedorRequestDto(
    [property: Required, StringLength(20)] string RucDocumento,
    [property: Required, StringLength(180)] string RazonSocial,
    [property: StringLength(250)] string? Direccion,
    [property: StringLength(30)] string? Telefono,
    [property: StringLength(150)] string? Correo,
    [property: StringLength(150)] string? Contacto);

public sealed record ProveedorFiltersDto(
    string? Texto = null,
    bool? Activo = null);

public sealed record ProveedorListItemDto(
    long Id,
    string RucDocumento,
    string RazonSocial,
    string? Direccion,
    string? Telefono,
    string? Correo,
    string? Contacto,
    bool Activo,
    DateTime CreadoEn,
    DateTime? ActualizadoEn);

public sealed record ProveedorDetailDto(
    long Id,
    string RucDocumento,
    string RazonSocial,
    string? Direccion,
    string? Telefono,
    string? Correo,
    string? Contacto,
    bool Activo,
    DateTime CreadoEn,
    DateTime? ActualizadoEn);

public sealed record ProveedorLookupDto(
    long Id,
    string RucDocumento,
    string RazonSocial);
