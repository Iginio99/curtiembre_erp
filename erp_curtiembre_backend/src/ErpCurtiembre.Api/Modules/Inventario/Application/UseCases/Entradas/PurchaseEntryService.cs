using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Entradas;

public sealed class PurchaseEntryService(
    IEntradaInventarioRepository entradaInventarioRepository,
    IOrdenCompraRepository ordenCompraRepository,
    IInsumoRepository insumoRepository,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<UseCaseResult<EntradaInventarioDetailDto>> RegisterAsync(
        RegistrarEntradaCompraRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.DocumentoSoporte))
        {
            errors.Add("El documento soporte es obligatorio.");
        }

        if (request.Observacion is not null && string.IsNullOrWhiteSpace(request.Observacion))
        {
            errors.Add("La observacion no puede estar vacia.");
        }

        if (request.Detalles.Count == 0)
        {
            errors.Add("Debes registrar al menos un detalle.");
        }

        var ordenCompra = await ordenCompraRepository.FindByIdAsync(request.OrdenCompraId, cancellationToken);
        if (ordenCompra is null)
        {
            errors.Add("No se encontro la orden de compra seleccionada.");
        }
        else if (!string.Equals(ordenCompra.Estado, "APROBADA", StringComparison.OrdinalIgnoreCase) &&
                 !string.Equals(ordenCompra.Estado, "PARCIALMENTE_RECIBIDA", StringComparison.OrdinalIgnoreCase))
        {
            errors.Add("Solo se puede registrar entrada para ordenes APROBADAS o PARCIALMENTE_RECIBIDAS.");
        }

        var orderDetails = ordenCompra is null
            ? Array.Empty<OrdenCompraDetalle>()
            : await ordenCompraRepository.ListDetailsAsync(request.OrdenCompraId, cancellationToken);

        var detailsById = orderDetails.ToDictionary(item => item.Id);
        var processedDetailIds = new HashSet<long>();
        var details = new List<PurchaseEntryRegistrationDetail>();

        foreach (var detail in request.Detalles)
        {
            if (!processedDetailIds.Add(detail.OrdenCompraDetalleId))
            {
                errors.Add($"El detalle de compra {detail.OrdenCompraDetalleId} no debe repetirse.");
                continue;
            }

            if (!detailsById.TryGetValue(detail.OrdenCompraDetalleId, out var orderDetail))
            {
                errors.Add($"No se encontro el detalle de compra {detail.OrdenCompraDetalleId}.");
                continue;
            }

            if (orderDetail.InsumoId != detail.InsumoId)
            {
                errors.Add($"El insumo del detalle {detail.OrdenCompraDetalleId} no coincide con la orden de compra.");
                continue;
            }

            if (detail.Cantidad <= 0)
            {
                errors.Add($"La cantidad recibida del insumo {orderDetail.InsumoCodigo} debe ser mayor que 0.");
                continue;
            }

            if (detail.CostoUnitario < 0)
            {
                errors.Add($"El costo unitario del insumo {orderDetail.InsumoCodigo} no puede ser negativo.");
                continue;
            }

            if (detail.Observacion is not null && string.IsNullOrWhiteSpace(detail.Observacion))
            {
                errors.Add($"La observacion del insumo {orderDetail.InsumoCodigo} no puede estar vacia.");
                continue;
            }

            if (detail.Cantidad > orderDetail.SaldoPendiente)
            {
                errors.Add(
                    $"La cantidad recibida del insumo {orderDetail.InsumoCodigo} no puede superar el saldo pendiente ({orderDetail.SaldoPendiente}).");
                continue;
            }

            var insumo = await insumoRepository.FindByIdAsync(detail.InsumoId, cancellationToken);
            if (insumo is null)
            {
                errors.Add($"No se encontro el insumo {detail.InsumoId}.");
                continue;
            }

            details.Add(new PurchaseEntryRegistrationDetail(
                detail.OrdenCompraDetalleId,
                detail.InsumoId,
                detail.Cantidad,
                detail.CostoUnitario,
                NormalizeNullable(detail.Observacion)));
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<EntradaInventarioDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync("EI", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<EntradaInventarioDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        long entryId;
        try
        {
            entryId = await entradaInventarioRepository.RegisterFromPurchaseAsync(
                new PurchaseEntryRegistration(
                    codigo,
                    request.OrdenCompraId,
                    dateTimeProvider.Now,
                    request.DocumentoSoporte.Trim(),
                    NormalizeNullable(request.Observacion),
                    actorId,
                    details),
                cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<EntradaInventarioDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        var entry = await entradaInventarioRepository.FindByIdAsync(entryId, cancellationToken);
        if (entry is null)
        {
            return UseCaseResult<EntradaInventarioDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se pudo recuperar la entrada registrada.");
        }

        var persistedDetails = await entradaInventarioRepository.ListDetailsAsync(entryId, cancellationToken);

        return UseCaseResult<EntradaInventarioDetailDto>.Ok(
            new EntradaInventarioDetailDto(
                entry.Id,
                entry.Codigo,
                entry.TipoEntrada,
                entry.FechaEntrada,
                entry.DocumentoSoporte,
                entry.Observacion,
                entry.Estado,
                entry.CreadoPorUsuarioId,
                entry.CreadoEn,
                persistedDetails.Select(MapDetail).ToArray()),
            "Entrada desde compra registrada correctamente.");
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static EntradaInventarioDetalleDto MapDetail(EntradaInventarioDetalle detail) =>
        new(
            detail.Id,
            detail.InsumoId,
            detail.InsumoCodigo,
            detail.InsumoNombre,
            detail.Cantidad,
            detail.CostoUnitario,
            detail.CostoTotal,
            detail.StockActual,
            detail.UnidadMedidaCodigo,
            detail.UnidadMedidaNombre,
            detail.Observacion);
}
