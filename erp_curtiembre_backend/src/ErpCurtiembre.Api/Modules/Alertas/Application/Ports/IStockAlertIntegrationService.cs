namespace ErpCurtiembre.Modules.Alertas.Application.Ports;

public interface IStockAlertIntegrationService
{
    Task SyncLowStockAlertsAsync(IReadOnlyCollection<long> insumoIds, CancellationToken cancellationToken);
}
