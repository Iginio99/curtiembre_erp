namespace ErpCurtiembre.Modules.Alertas.Application.Ports;

public interface IAlertaCommandService
{
    Task<bool> MarkAsReadAsync(long usuarioId, long alertaId, CancellationToken cancellationToken);

    Task<bool> CloseAsync(
        long usuarioId,
        long alertaId,
        string? comentario,
        CancellationToken cancellationToken);
}
