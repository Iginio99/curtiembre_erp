namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public sealed record InventarioFisicoRegistration(
    string Codigo,
    DateTime FechaInicio,
    int PeriodoAnio,
    int PeriodoMes,
    long EjecutadoPorUsuarioId,
    string? Observacion);

public sealed record InventarioFisicoCountRegistrationDetail(
    long InsumoId,
    decimal StockContado,
    string? Observacion);

public sealed record InventarioFisicoCloseRegistration(
    long InventarioFisicoId,
    DateTime FechaCierre,
    long UsuarioResponsableId,
    string? Observacion,
    string? CodigoAjustePositivo,
    string? CodigoAjusteNegativo);
