namespace ErpCurtiembre.Modules.Alertas.Domain.Entities;

public sealed record ResumenAlertas(
    int TotalPendientes,
    int TotalLeidas,
    int TotalAlta,
    int TotalMedia,
    int TotalBaja,
    int StockBajo,
    int OrdenesActivas,
    int ComprasPendientes,
    int OrdenesRetrasadas,
    decimal CostoPromedioOrden,
    IReadOnlyCollection<AlertaSistema> Recientes);
