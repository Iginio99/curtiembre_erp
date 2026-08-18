using System.ComponentModel.DataAnnotations;

namespace ErpCurtiembre.Modules.Seguridad.Application.DTOs;

public sealed record LoginRequestDto(
    [property: Required, StringLength(60, MinimumLength = 3)] string UserName,
    [property: Required, StringLength(100, MinimumLength = 8)] string Password,
    string? Ip = null,
    string? UserAgent = null);

public sealed record LoginResultDto(
    long UsuarioId,
    string UserName,
    string NombreCompleto,
    string RolCodigo,
    string RolNombre,
    bool DebeCambiarPassword,
    string SessionToken,
    DateTime ExpiraEn);

public sealed record LogoutResultDto(string Message);

public sealed record ChangePasswordRequestDto(
    [property: Required, StringLength(100, MinimumLength = 8)] string CurrentPassword,
    [property: Required, StringLength(100, MinimumLength = 8)] string NewPassword,
    [property: Required, StringLength(100, MinimumLength = 8)] string ConfirmPassword);

public sealed record SessionInfoDto(
    long SesionId,
    long UsuarioId,
    long RolId,
    string UserName,
    string NombreCompleto,
    string RolCodigo,
    string RolNombre,
    bool DebeCambiarPassword,
    DateTime ExpiraEn);
