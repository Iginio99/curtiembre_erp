namespace ErpCurtiembre.Modules.Seguridad.Domain.Rules;

public static class LoginPolicy
{
    public const int MaxIntentosFallidos = 5;
    public const int MinutosBloqueo = 5;
    public const int MinutosSesion = 30;
}
