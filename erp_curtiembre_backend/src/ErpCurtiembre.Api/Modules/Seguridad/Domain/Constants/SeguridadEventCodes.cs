namespace ErpCurtiembre.Modules.Seguridad.Domain.Constants;

public static class SeguridadEventCodes
{
    public const string LoginExitoso = "LOGIN_EXITOSO";
    public const string LoginFallido = "LOGIN_FALLIDO";
    public const string UsuarioBloqueado = "USUARIO_BLOQUEADO";
    public const string PasswordCambiado = "PASSWORD_CAMBIADO";
    public const string PasswordReseteado = "PASSWORD_RESETEADO";
    public const string UsuarioCreado = "USUARIO_CREADO";
    public const string UsuarioActualizado = "USUARIO_ACTUALIZADO";
    public const string RolCambiado = "ROL_CAMBIADO";
    public const string UsuarioDesactivado = "USUARIO_DESACTIVADO";
    public const string UsuarioReactivado = "USUARIO_REACTIVADO";
    public const string PermisoDenegado = "PERMISO_DENEGADO";
    public const string Logout = "LOGOUT";
    public const string SesionExpirada = "SESION_EXPIRADA";
}
