using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.UseCases.Salidas;
using ErpCurtiembre.Modules.Produccion.Application.Ports;

namespace ErpCurtiembre.Modules.Produccion.Infrastructure.Services;

public sealed class ProduccionInventarioGateway(SalidaInventarioService salidaInventarioService) : IProduccionInventarioGateway
{
    public async Task<InventoryProcessConsumptionResult> RegisterProcessConsumptionAsync(
        long ordenProduccionId,
        long ordenProcesoId,
        string motivo,
        string? observacion,
        IReadOnlyCollection<InventoryProcessConsumptionDetailRequest> detalles,
        long actorId,
        CancellationToken cancellationToken)
    {
        var result = await salidaInventarioService.RegisterProcessAsync(
            new RegistrarSalidaProcesoRequestDto(
                ordenProduccionId,
                ordenProcesoId,
                motivo,
                observacion,
                detalles.Select(x => new RegistrarSalidaDetalleRequestDto(
                    x.InsumoId,
                    x.Cantidad,
                    x.Observacion)).ToArray()),
            actorId,
            cancellationToken);

        if (!result.Success || result.Data is null)
        {
            return new InventoryProcessConsumptionResult(
                false,
                result.Message,
                result.ErrorCode,
                null,
                Array.Empty<InventoryProcessConsumptionDetailResult>());
        }

        return new InventoryProcessConsumptionResult(
            true,
            result.Message,
            null,
            result.Data.Id,
            result.Data.Detalles.Select(x => new InventoryProcessConsumptionDetailResult(
                x.Id,
                x.InsumoId,
                x.Cantidad,
                x.CostoUnitario,
                x.CostoTotal)).ToArray());
    }
}
