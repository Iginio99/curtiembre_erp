using System.Security.Cryptography;
using System.Text;
using ErpCurtiembre.Modules.Seguridad.Application.Ports;

namespace ErpCurtiembre.Modules.Seguridad.Infrastructure.Services;

public sealed class SessionTokenService : ISessionTokenService
{
    public string GenerateToken() => Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));

    public string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }
}
