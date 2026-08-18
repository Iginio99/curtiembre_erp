using ErpCurtiembre.Modules.Alertas.Application.DTOs;
using ErpCurtiembre.Modules.Alertas.Application.Ports;

namespace ErpCurtiembre.Modules.Alertas.Application.UseCases;

public sealed class ListarAlertasUseCase(IAlertaQueryService alertaQueryService)
{
    public async Task<IReadOnlyCollection<AlertaActivaDto>> ExecuteAsync(
        long usuarioId,
        AlertaFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await alertaQueryService.ListAsync(usuarioId, filters, cancellationToken);
        return items.Select(MapActiva).ToArray();
    }

    private static AlertaActivaDto MapActiva(ErpCurtiembre.Modules.Alertas.Domain.Entities.AlertaSistema item)
        => new(
            item.Id,
            item.TipoAlerta,
            item.Titulo,
            item.Mensaje,
            item.Severidad,
            item.Estado,
            item.ModuloOrigen,
            item.EntidadOrigen,
            item.EntidadOrigenId,
            item.GeneradaEn);
}

public sealed class ObtenerAlertaDetalleUseCase(IAlertaQueryService alertaQueryService)
{
    public async Task<AlertaDetalleDto?> ExecuteAsync(
        long usuarioId,
        long alertaId,
        CancellationToken cancellationToken)
    {
        var item = await alertaQueryService.FindByIdAsync(usuarioId, alertaId, cancellationToken);
        if (item is null)
        {
            return null;
        }

        return new AlertaDetalleDto(
            item.Id,
            item.TipoAlerta,
            item.Titulo,
            item.Mensaje,
            item.Severidad,
            item.Estado,
            item.ModuloOrigen,
            item.EntidadOrigen,
            item.EntidadOrigenId,
            item.GeneradaEn,
            item.LeidaEn,
            item.CerradaEn);
    }
}

public sealed class ObtenerResumenAlertasUseCase(IAlertaQueryService alertaQueryService)
{
    public async Task<AlertasResumenDto> ExecuteAsync(long usuarioId, CancellationToken cancellationToken)
    {
        var summary = await alertaQueryService.GetSummaryAsync(usuarioId, cancellationToken);

        return new AlertasResumenDto(
            summary.TotalPendientes,
            summary.TotalLeidas,
            summary.TotalAlta,
            summary.TotalMedia,
            summary.TotalBaja,
            summary.Recientes
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
                .ToArray());
    }
}

public sealed class ListarHistorialAlertaUseCase(IAlertaQueryService alertaQueryService)
{
    public async Task<IReadOnlyCollection<AlertaHistorialDto>> ExecuteAsync(
        long usuarioId,
        long alertaId,
        CancellationToken cancellationToken)
    {
        var items = await alertaQueryService.ListHistorialAsync(usuarioId, alertaId, cancellationToken);

        return items.Select(item => new AlertaHistorialDto(
            item.Id,
            item.EstadoAnterior,
            item.EstadoNuevo,
            item.Comentario,
            item.CambiadoPorUsuarioId,
            item.CambiadoPorNombre,
            item.CambiadoEn)).ToArray();
    }
}
