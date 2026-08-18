namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface ISessionTokenService
{
    string GenerateToken();

    string HashToken(string token);
}
