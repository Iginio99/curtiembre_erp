using System.Text.RegularExpressions;

namespace ErpCurtiembre.Modules.Seguridad.Domain.Rules;

public static partial class PasswordPolicyRule
{
    public static IReadOnlyCollection<string> Validate(string password, string? confirmPassword = null)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(password) || password.Length < 8)
        {
            errors.Add("La contrasena debe tener minimo 8 caracteres.");
        }

        if (!UppercaseRegex().IsMatch(password))
        {
            errors.Add("La contrasena debe incluir al menos una mayuscula.");
        }

        if (!LowercaseRegex().IsMatch(password))
        {
            errors.Add("La contrasena debe incluir al menos una minuscula.");
        }

        if (!DigitRegex().IsMatch(password))
        {
            errors.Add("La contrasena debe incluir al menos un numero.");
        }

        if (confirmPassword is not null && !string.Equals(password, confirmPassword, StringComparison.Ordinal))
        {
            errors.Add("Las contrasenas no coinciden.");
        }

        return errors;
    }

    [GeneratedRegex("[A-Z]")]
    private static partial Regex UppercaseRegex();

    [GeneratedRegex("[a-z]")]
    private static partial Regex LowercaseRegex();

    [GeneratedRegex("[0-9]")]
    private static partial Regex DigitRegex();
}
