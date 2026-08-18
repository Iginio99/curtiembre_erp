using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Seguridad.Application.DTOs;

public sealed record CreateUserRequestDto(
    [property: Required, StringLength(20, MinimumLength = 8)] string Dni,
    [property: Required, StringLength(120)] string Nombres,
    [property: Required, StringLength(120)] string Apellidos,
    [property: Required, StringLength(60, MinimumLength = 3)] string UserName,
    [property: Range(1, long.MaxValue)] long RolId,
    [property: Range(1, long.MaxValue)] long AreaId,
    string? PasswordTemporal = null);

public sealed record UpdateUserRequestDto(
    [property: Required, StringLength(20, MinimumLength = 8)] string Dni,
    [property: Required, StringLength(120)] string Nombres,
    [property: Required, StringLength(120)] string Apellidos,
    [property: Required, StringLength(60, MinimumLength = 3)] string UserName,
    [property: Range(1, long.MaxValue)] long RolId,
    [property: Range(1, long.MaxValue)] long AreaId);

public sealed record ResetPasswordRequestDto(string? PasswordTemporal = null);

public sealed record UserStateChangeRequestDto([property: StringLength(250)] string? Motivo = null);

public sealed record UserFiltersDto(
    string? Texto = null,
    long? RolId = null,
    long? AreaId = null,
    bool? Activo = null,
    int Page = 1,
    int PageSize = 20);

public sealed record UserListItemDto(
    long UsuarioId,
    string Dni,
    string Nombres,
    string Apellidos,
    string UserName,
    long RolId,
    string RolNombre,
    long? AreaId,
    string? AreaNombre,
    bool Activo,
    bool DebeCambiarPassword,
    int IntentosFallidos,
    DateTime? BloqueadoHasta,
    DateTime? UltimoLoginEn);

public sealed record UserDetailDto(
    long UsuarioId,
    string Dni,
    string Nombres,
    string Apellidos,
    string UserName,
    long RolId,
    string RolCodigo,
    string RolNombre,
    long? AreaId,
    string? AreaNombre,
    bool Activo,
    bool DebeCambiarPassword,
    int IntentosFallidos,
    DateTime? BloqueadoHasta,
    DateTime? UltimoLoginEn,
    DateTime CreadoEn);

public sealed record UserMutationResultDto(
    UserDetailDto Usuario,
    string? PasswordTemporal = null);
