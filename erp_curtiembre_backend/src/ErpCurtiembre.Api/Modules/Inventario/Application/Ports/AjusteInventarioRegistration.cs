namespace ErpCurtiembre.Modules.Inventario.Application.Ports;

public sealed record AjusteInventarioRegistration(
    string Codigo,
    string TipoAjuste,
    DateTime FechaAjuste,
    string Motivo,
    string? Observacion,
    long UsuarioResponsableId,
    IReadOnlyCollection<AjusteInventarioRegistrationDetail> Detalles);

public sealed record AjusteInventarioRegistrationDetail(
    long InsumoId,
    decimal Cantidad,
    decimal? CostoUnitario);
