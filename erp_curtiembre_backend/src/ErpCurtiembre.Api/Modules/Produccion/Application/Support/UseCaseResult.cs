namespace ErpCurtiembre.Modules.Produccion.Application.Support;

public sealed record UseCaseResult<T>(
    bool Success,
    string Message,
    string? ErrorCode = null,
    T? Data = default)
{
    public static UseCaseResult<T> Ok(T data, string message = "Operacion exitosa.") =>
        new(true, message, null, data);

    public static UseCaseResult<T> Fail(string errorCode, string message) =>
        new(false, message, errorCode);
}
