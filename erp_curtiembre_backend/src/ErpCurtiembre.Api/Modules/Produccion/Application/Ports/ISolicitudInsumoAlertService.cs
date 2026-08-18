namespace ErpCurtiembre.Modules.Produccion.Application.Ports;

public interface ISolicitudInsumoAlertService
{
    Task CreatePendingAsync(long solicitudId, string codigo, CancellationToken cancellationToken);

    Task CloseAsync(long solicitudId, long actorId, CancellationToken cancellationToken);
}
