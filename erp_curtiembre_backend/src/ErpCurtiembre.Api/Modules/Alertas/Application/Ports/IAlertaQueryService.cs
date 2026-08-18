using ErpCurtiembre.Modules.Alertas.Application.DTOs;
using ErpCurtiembre.Modules.Alertas.Domain.Entities;

namespace ErpCurtiembre.Modules.Alertas.Application.Ports;

public interface IAlertaQueryService
{
    Task<IReadOnlyCollection<AlertaSistema>> ListActivasAsync(long usuarioId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<AlertaSistema>> ListAsync(
        long usuarioId,
        AlertaFiltersDto filters,
        CancellationToken cancellationToken);

    Task<AlertaDetalle?> FindByIdAsync(long usuarioId, long alertaId, CancellationToken cancellationToken);

    Task<ResumenAlertas> GetSummaryAsync(long usuarioId, CancellationToken cancellationToken);

    Task<IReadOnlyCollection<AlertaHistorialItem>> ListHistorialAsync(
        long usuarioId,
        long alertaId,
        CancellationToken cancellationToken);
}
