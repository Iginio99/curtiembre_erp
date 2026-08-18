namespace ErpCurtiembre.Modules.Seguridad.Application.Ports;

public interface IPasswordHasher
{
    string HashPassword(string rawPassword);

    bool VerifyPassword(string rawPassword, string passwordHash);

    string GenerateTemporaryPassword();
}
