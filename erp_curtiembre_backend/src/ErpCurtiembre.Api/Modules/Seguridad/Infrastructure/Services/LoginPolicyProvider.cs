using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Domain.Constants;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;
using ErpCurtiembre.Modules.Seguridad.Domain.Rules;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Services;

public sealed class LoginPolicyProvider(IConfiguracionQueryService configuracionQueryService) : ILoginPolicyProvider
{
    public async Task<LoginPolicySettings> GetAsync(CancellationToken cancellationToken)
    {
        var parameters = await configuracionQueryService.GetByClavesAsync(
            [
                ParametroSistemaKeys.IntentosLoginMax,
                ParametroSistemaKeys.MinutosBloqueoLogin,
                ParametroSistemaKeys.MinutosInactividadSesion
            ],
            cancellationToken);

        return new LoginPolicySettings(
            ParseInt(parameters, ParametroSistemaKeys.IntentosLoginMax, LoginPolicy.MaxIntentosFallidos),
            ParseInt(parameters, ParametroSistemaKeys.MinutosBloqueoLogin, LoginPolicy.MinutosBloqueo),
            ParseInt(parameters, ParametroSistemaKeys.MinutosInactividadSesion, LoginPolicy.MinutosSesion));
    }

    private static int ParseInt(
        IReadOnlyDictionary<string, Configuracion.Domain.Entities.ParametroSistema> parameters,
        string key,
        int fallback)
    {
        if (!parameters.TryGetValue(key, out var parameter))
        {
            return fallback;
        }

        return int.TryParse(parameter.Valor, out var parsedValue) && parsedValue > 0
            ? parsedValue
            : fallback;
    }
}
