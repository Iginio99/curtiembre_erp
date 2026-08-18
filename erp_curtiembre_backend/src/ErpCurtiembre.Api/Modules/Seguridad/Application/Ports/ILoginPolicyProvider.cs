namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface ILoginPolicyProvider
{
    Task<LoginPolicySettings> GetAsync(CancellationToken cancellationToken);
}
