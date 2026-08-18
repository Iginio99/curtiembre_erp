using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Seguridad.Application.DTOs;

public sealed record RoleDto(
    long Id,
    string Codigo,
    string Nombre,
    string? Descripcion,
    bool Activo);

public sealed record PermissionFiltersDto(
    string? Modulo = null,
    string? Accion = null,
    bool? Activo = null);

public sealed record PermissionDto(
    long Id,
    string Codigo,
    string Modulo,
    string Accion,
    string? Descripcion,
    bool Activo);

public sealed record UserPermissionsDto(long UsuarioId, IReadOnlyCollection<string> PermissionCodes);

public sealed record CheckPermissionRequestDto(
    [property: Range(1, long.MaxValue)] long UsuarioId,
    [property: Required, StringLength(120)] string PermissionCode);

public sealed record CheckPermissionResultDto(long UsuarioId, string PermissionCode, bool Allowed);
