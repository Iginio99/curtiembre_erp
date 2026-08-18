using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Configuracion.Domain.Constants;
using ErpCurtiembre.Modules.Finanzas.Application.DTOs;
using ErpCurtiembre.Modules.Finanzas.Application.Ports;
using ErpCurtiembre.Modules.Finanzas.Application.Support;
using ErpCurtiembre.Modules.Finanzas.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Finanzas.Application.UseCases.Pricing;

public sealed class PrecioSugeridoService(
    IPrecioSugeridoRepository precioSugeridoRepository,
    ICostoOrdenRepository costoOrdenRepository,
    IConfiguracionQueryService configuracionQueryService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<PrecioSugeridoDetailDto>> GetByOrderIdAsync(long ordenProduccionId, CancellationToken cancellationToken)
    {
        var item = await precioSugeridoRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        return item is null
            ? UseCaseResult<PrecioSugeridoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se encontro el precio sugerido de la orden.")
            : UseCaseResult<PrecioSugeridoDetailDto>.Ok(MapDetail(item));
    }

    public async Task<UseCaseResult<PrecioSugeridoDetailDto>> CalculateAsync(
        long ordenProduccionId,
        CalcularPrecioSugeridoRequestDto request,
        CancellationToken cancellationToken)
    {
        if (request.MargenPorcentaje < 0)
        {
            return UseCaseResult<PrecioSugeridoDetailDto>.Fail(
                FinanzasErrorCodes.Validation,
                "El margen no puede ser negativo.");
        }

        var costoOrden = await costoOrdenRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        if (costoOrden is null)
        {
            return UseCaseResult<PrecioSugeridoDetailDto>.Fail(
                FinanzasErrorCodes.NotFound,
                "No existe un costo de orden para calcular el precio sugerido.");
        }

        var costoBase = costoOrden.CostoReal ?? costoOrden.CostoEstimado;
        if (costoBase is null)
        {
            return UseCaseResult<PrecioSugeridoDetailDto>.Fail(
                FinanzasErrorCodes.Conflict,
                "La orden no tiene un costo base disponible.");
        }

        var parametros = await configuracionQueryService.GetByClavesAsync(
            [ParametroSistemaKeys.IgvPorcentaje],
            cancellationToken);
        var igv = TryGetDecimal(parametros, ParametroSistemaKeys.IgvPorcentaje) ?? 18m;

        var entity = new PrecioSugerido
        {
            OrdenProduccionId = costoOrden.OrdenProduccionId,
            OrdenProduccionCodigo = costoOrden.OrdenProduccionCodigo,
            CostoBaseSinIgv = decimal.Round(costoBase.Value, 2),
            MargenPorcentaje = request.MargenPorcentaje,
            IgvPorcentaje = igv,
            CalculadoEn = dateTimeProvider.Now
        };

        await precioSugeridoRepository.UpsertAsync(entity, cancellationToken);
        var stored = await precioSugeridoRepository.FindByOrderIdAsync(ordenProduccionId, cancellationToken);
        return stored is null
            ? UseCaseResult<PrecioSugeridoDetailDto>.Fail(FinanzasErrorCodes.NotFound, "No se pudo recuperar el precio sugerido calculado.")
            : UseCaseResult<PrecioSugeridoDetailDto>.Ok(MapDetail(stored), "Precio sugerido calculado correctamente.");
    }

    private static decimal? TryGetDecimal(IReadOnlyDictionary<string, Modules.Configuracion.Domain.Entities.ParametroSistema> parametros, string key)
    {
        if (!parametros.TryGetValue(key, out var parametro))
        {
            return null;
        }

        return decimal.TryParse(parametro.Valor, out var value) ? value : null;
    }

    private static PrecioSugeridoDetailDto MapDetail(PrecioSugerido item) =>
        new(
            item.Id,
            item.OrdenProduccionId,
            item.OrdenProduccionCodigo,
            item.CostoBaseSinIgv,
            item.MargenPorcentaje,
            item.PrecioSugeridoSinIgv,
            item.IgvPorcentaje,
            item.PrecioSugeridoConIgv,
            item.CalculadoEn);
}
