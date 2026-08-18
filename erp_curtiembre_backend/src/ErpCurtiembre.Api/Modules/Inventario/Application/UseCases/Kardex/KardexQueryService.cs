using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Kardex;

public sealed class KardexQueryService(IKardexRepository kardexRepository)
{
    public async Task<IReadOnlyCollection<KardexMovimientoDto>> ListAsync(
        KardexFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await kardexRepository.ListAsync(filters, cancellationToken);
        return items.Select(Map).ToArray();
    }

    public async Task<IReadOnlyCollection<KardexMovimientoDto>> ListByInsumoAsync(
        long insumoId,
        KardexFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await kardexRepository.ListByInsumoAsync(insumoId, filters, cancellationToken);
        return items.Select(Map).ToArray();
    }

    private static KardexMovimientoDto Map(Domain.Entities.KardexMovimiento item) =>
        new(
            item.Id,
            item.FechaMovimiento,
            item.InsumoId,
            item.InsumoCodigo,
            item.InsumoNombre,
            item.TipoMovimiento,
            item.DocumentoTipo,
            item.DocumentoId,
            item.Entrada,
            item.Salida,
            item.StockActual,
            item.EstadoStock,
            item.CostoUnitario,
            item.CostoTotal,
            item.UsuarioResponsableId,
            item.UsuarioResponsable,
            item.Observacion);
}
