namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public sealed record LoginPolicySettings(
    int MaxIntentosFallidos,
    int MinutosBloqueo,
    int MinutosSesion);
