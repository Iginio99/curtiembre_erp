using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Produccion.Application.DTOs;

public sealed record CreateClienteRequestDto(
    [property: Required, StringLength(20)] string RucDocumento,
    [property: Required, StringLength(180)] string RazonSocial,
    [property: StringLength(250)] string? Direccion,
    [property: StringLength(30)] string? Celular,
    [property: StringLength(150)] string? Correo,
    [property: StringLength(150)] string? Contacto);

public sealed record UpdateClienteRequestDto(
    [property: Required, StringLength(20)] string RucDocumento,
    [property: Required, StringLength(180)] string RazonSocial,
    [property: StringLength(250)] string? Direccion,
    [property: StringLength(30)] string? Celular,
    [property: StringLength(150)] string? Correo,
    [property: StringLength(150)] string? Contacto);

public sealed record ClienteFiltersDto(
    string? Texto = null,
    bool? Activo = null);

public sealed record ClienteListItemDto(
    long Id,
    string RucDocumento,
    string RazonSocial,
    string? Direccion,
    string? Celular,
    string? Correo,
    string? Contacto,
    bool Activo,
    DateTime CreadoEn,
    DateTime? ActualizadoEn);

public sealed record ClienteDetailDto(
    long Id,
    string RucDocumento,
    string RazonSocial,
    string? Direccion,
    string? Celular,
    string? Correo,
    string? Contacto,
    bool Activo,
    DateTime CreadoEn,
    DateTime? ActualizadoEn);

public sealed record ClienteLookupDto(
    long Id,
    string RucDocumento,
    string RazonSocial);
