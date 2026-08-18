using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Pricing;

public sealed class RentabilidadOrdenService(
    IRentabilidadOrdenRepository rentabilidadOrdenRepository,
    ICostoOrdenRepository costoOrdenRepository,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<RentabilidadOrdenDetailDto>> GetByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken)
    {
        var item = await rentabilidadOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        return item is null
            ? UseCaseResult<RentabilidadOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro la rentabilidad de la orden.")
            : UseCaseResult<RentabilidadOrdenDetailDto>.Ok(MapDetail(item));
    }

    public async Task<UseCaseResult<RentabilidadOrdenDetailDto>> CalculateAsync(
        long ordenProduccionId,
        CalcularRentabilidadRequestDto request,
        CancellationToken cancellationToken)
    {
        if (request.PrecioVenta < 0)
        {
            return UseCaseResult<RentabilidadOrdenDetailDto>.Fail(
                FinanzasErrorCodes.Validation,
                "El precio de venta no puede ser negativo.");
        }

        var costoOrden = await costoOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        if (costoOrden is null)
        {
            return UseCaseResult<RentabilidadOrdenDetailDto>.Fail(
                FinanzasErrorCodes.NotFound,
                "No existe un costo de orden para calcular la rentabilidad.");
        }

        var costoTotal = costoOrden.CostoReal ?? costoOrden.CostoEstimado;
        if (costoTotal is null)
        {
            return UseCaseResult<RentabilidadOrdenDetailDto>.Fail(
                FinanzasErrorCodes.Conflict,
                "La orden no tiene un costo base disponible.");
        }

        var utilidad = decimal.Round(request.PrecioVenta - costoTotal.Value, 2);
        decimal? margenPorcentaje = costoTotal.Value > 0
            ? decimal.Round((utilidad / costoTotal.Value) * 100, 4, MidpointRounding.AwayFromZero)
            : null;

        var entity = new RentabilidadOrden
        {
            OrdenProduccionId = costoOrden.OrdenProduccionId,
            OrdenProduccionCodigo = costoOrden.OrdenProduccionCodigo,
            PrecioVenta = decimal.Round(request.PrecioVenta, 2),
            CostoTotal = decimal.Round(costoTotal.Value, 2),
            MargenPorcentaje = margenPorcentaje,
            CalculadoEn = dateTimeProvider.Now
        };

        await rentabilidadOrdenRepository.UpsertAsync(entity, cancellationToken);
        var stored = await rentabilidadOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        return stored is null
            ? UseCaseResult<RentabilidadOrdenDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar la rentabilidad calculada.")
            : UseCaseResult<RentabilidadOrdenDetailDto>.Ok(MapDetail(stored), "Rentabilidad calculada correctamente.");
    }

    private static RentabilidadOrdenDetailDto MapDetail(RentabilidadOrden item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProduccionCodigo,
            item.PrecioVenta,
            item.CostoTotal,
            item.Utilidad,
            item.MargenPorcentaje,
            item.CalculadoEn);
}
