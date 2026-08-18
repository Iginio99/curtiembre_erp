namespace ErpCurtiembre.Modules.Seguridad.Application.Support;

public static class SeguridadErrorCodes
{
    public const string Validation = "validation_error";
    public const string NotFound = "not_found";
    public const string Conflict = "conflict";
    public const string InvalidCredentials = "invalid_credentials";
    public const string UserBlocked = "user_blocked";
    public const string InactiveUser = "inactive_user";
    public const string PermissionDenied = "permission_denied";
    public const string SessionRequired = "session_required";
    public const string SessionExpired = "session_expired";
}
