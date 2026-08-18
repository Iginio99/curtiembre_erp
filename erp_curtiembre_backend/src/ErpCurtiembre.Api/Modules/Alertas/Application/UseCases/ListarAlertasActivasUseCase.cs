using ErpCurtiembre.Modules.Alertas.Application.DTOs;
using ErpCurtiembre.Modules.Alertas.Application.Ports;

namespace ErpCurtiembre.Modules.Alertas.Application.UseCases;

public sealed class ListarAlertasActivasUseCase(IAlertaQueryService alertaQueryService)
{
    public async Task<IReadOnlyCollection<AlertaActivaDto>> ExecuteAsync(
        long usuarioId,
        CancellationToken cancellationToken)
    {
        var items = await alertaQueryService.ListActivasAsync(usuarioId, cancellationToken);

        return items
            .Select(item => new AlertaActivaDto(
                item.Id,
                item.TipoAlerta,
                item.Titulo,
                item.Mensaje,
                item.Severidad,
                item.Estado,
                item.ModuloOrigen,
                item.EntidadOrigen,
                item.EntidadOrigenId,
                item.GeneradaEn))
            .ToArray();
    }
}
