namespace ErpCurtiembre.Modules.Alertas.Domain.Entities;

public sealed record ResumenAlertas(
    int TotalPendientes,
    int TotalLeidas,
    int TotalAlta,
    int TotalMedia,
    int TotalBaja,
    IReadOnlyCollection<AlertaSistema> Recientes);
