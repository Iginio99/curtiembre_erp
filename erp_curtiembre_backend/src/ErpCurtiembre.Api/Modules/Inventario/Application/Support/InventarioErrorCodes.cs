namespace ErpCurtiembre.Modules.Inventario.Application.Support;

public static class InventarioErrorCodes
{
    public const string Validation = "validation_error";
    public const string NotFound = "not_found";
    public const string Conflict = "conflict";
    public const string PermissionDenied = "permission_denied";
    public const string SessionRequired = "session_required";
    public const string SessionExpired = "session_expired";
}
