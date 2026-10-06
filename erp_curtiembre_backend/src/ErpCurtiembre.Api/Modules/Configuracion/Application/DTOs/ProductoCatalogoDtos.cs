using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Configuracion.Application.DTOs;

public sealed record UpsertProductoCatalogoRequestDto(
    [property: Required, StringLength(50)] string Codigo,
    [property: Required, StringLength(120)] string Tipo,
    [property: Required, StringLength(150)] string Nombre,
    [property: StringLength(80)] string? Color);

public sealed record ProductoCatalogoDto(long Id, string Codigo, string Tipo, string Nombre, string? Color, bool Activo, DateTime CreadoEn);
