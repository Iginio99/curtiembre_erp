using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Stock;

public sealed class StockQueryService(IStockRepository stockRepository)
{
    public async Task<IReadOnlyCollection<StockActualDto>> ListAsync(
        StockFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await stockRepository.ListAsync(filters, cancellationToken);
        return items.Select(Map).ToArray();
    }

    public async Task<UseCaseResult<StockActualDto>> GetByInsumoIdAsync(long insumoId, CancellationToken cancellationToken)
    {
        var item = await stockRepository.GetByInsumoIdAsync(insumoId, cancellationToken);
        return item is null
            ? UseCaseResult<StockActualDto>.Fail(InventarioErrorCodes.NotFound, "No se encontro el stock del insumo.")
            : UseCaseResult<StockActualDto>.Ok(Map(item));
    }

    private static StockActualDto Map(Domain.Entities.StockActual item) =>
        new(
            item.InsumoId,
            item.Codigo,
            item.Nombre,
            item.TipoBien,
            item.UnidadMedidaCodigo,
            item.UnidadMedidaNombre,
            item.StockMinimo,
            item.CantidadActual,
            item.CostoPromedioActual,
            item.Activo,
            item.StockBajo,
            item.ActualizadoEn);
}
