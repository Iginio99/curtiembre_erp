namespace ErpCurtiembre.Api.IntegrationTests.Contracts;

internal sealed record LoginResponse(
    long UsuarioId,
    string UserName,
    string NombreCompleto,
    string RolCodigo,
    string RolNombre,
    bool DebeCambiarPassword,
    string SessionToken,
    DateTime ExpiraEn);

internal sealed record SessionInfoResponse(
    long SesionId,
    long UsuarioId,
    long RolId,
    string UserName,
    string NombreCompleto,
    string RolCodigo,
    string RolNombre,
    bool DebeCambiarPassword,
    DateTime ExpiraEn);

internal sealed record LogoutResponse(string Message);

internal sealed record UserListItemResponse(
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

internal sealed record UserDetailResponse(
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

internal sealed record UserMutationResponse(UserDetailResponse Usuario, string? PasswordTemporal);

internal sealed record RoleResponse(long Id, string Codigo, string Nombre, string? Descripcion, bool Activo);

internal sealed record PermissionResponse(
    long Id,
    string Codigo,
    string Modulo,
    string Accion,
    string? Descripcion,
    bool Activo);

internal sealed record UserPermissionsResponse(long UsuarioId, IReadOnlyCollection<string> PermissionCodes);

internal sealed record CheckPermissionResponse(long UsuarioId, string PermissionCode, bool Allowed);

internal sealed record AuditItemResponse(
    long Id,
    long? UsuarioAfectadoId,
    string? UsuarioAfectado,
    long? UsuarioAccionId,
    string? UsuarioAccion,
    string Evento,
    string? Descripcion,
    string? IpOrigen,
    DateTime CreadoEn);

internal sealed record ErrorResponse(string Error, string Message);
