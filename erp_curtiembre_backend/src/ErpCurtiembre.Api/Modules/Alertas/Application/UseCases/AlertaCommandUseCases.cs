using ErpCurtiembre.Modules.Alertas.Application.DTOs;
using ErpCurtiembre.Modules.Alertas.Application.Ports;

namespace ErpCurtiembre.Modules.Alertas.Application.UseCases;

public sealed class MarcarAlertaLeidaUseCase(
    IAlertaCommandService alertaCommandService,
    IAlertaQueryService alertaQueryService)
{
    public async Task<AlertaDetalleDto?> ExecuteAsync(
        long usuarioId,
        long alertaId,
        CancellationToken cancellationToken)
    {
        var updated = await alertaCommandService.MarkAsReadAsync(usuarioId, alertaId, cancellationToken);
        if (!updated)
        {
            return null;
        }

        var detail = await alertaQueryService.FindByIdAsync(usuarioId, alertaId, cancellationToken);
        if (detail is null)
        {
            return null;
        }

        return new AlertaDetalleDto(
            detail.Id,
            detail.TipoAlerta,
            detail.Titulo,
            detail.Mensaje,
            detail.Severidad,
            detail.Estado,
            detail.ModuloOrigen,
            detail.EntidadOrigen,
            detail.EntidadOrigenId,
            detail.GeneradaEn,
            detail.LeidaEn,
            detail.CerradaEn);
    }
}

public sealed class CerrarAlertaUseCase(
    IAlertaCommandService alertaCommandService,
    IAlertaQueryService alertaQueryService)
{
    public async Task<AlertaDetalleDto?> ExecuteAsync(
        long usuarioId,
        long alertaId,
        string? comentario,
        CancellationToken cancellationToken)
    {
        var updated = await alertaCommandService.CloseAsync(usuarioId, alertaId, comentario, cancellationToken);
        if (!updated)
        {
            return null;
        }

        var detail = await alertaQueryService.FindByIdAsync(usuarioId, alertaId, cancellationToken);
        if (detail is null)
        {
            return null;
        }

        return new AlertaDetalleDto(
            detail.Id,
            detail.TipoAlerta,
            detail.Titulo,
            detail.Mensaje,
            detail.Severidad,
            detail.Estado,
            detail.ModuloOrigen,
            detail.EntidadOrigen,
            detail.EntidadOrigenId,
            detail.GeneradaEn,
            detail.LeidaEn,
            detail.CerradaEn);
    }
}
