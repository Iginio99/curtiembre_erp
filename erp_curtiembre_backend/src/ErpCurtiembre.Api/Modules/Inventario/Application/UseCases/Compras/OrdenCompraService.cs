using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Compras;

public sealed class OrdenCompraService(
    IOrdenCompraRepository ordenCompraRepository,
    IProveedorRepository proveedorRepository,
    IInsumoRepository insumoRepository,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<OrdenCompraListItemDto>> ListAsync(
        OrdenCompraFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await ordenCompraRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapListItem).ToArray();
    }

    public async Task<UseCaseResult<OrdenCompraDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var ordenCompra = await ordenCompraRepository.FindByIdAsync(id, cancellationToken);
        if (ordenCompra is null)
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se encontro la orden de compra.");
        }

        var details = await ordenCompraRepository.ListDetailsAsync(id, cancellationToken);
        return UseCaseResult<OrdenCompraDetailDto>.Ok(MapDetail(ordenCompra, details));
    }

    public async Task<UseCaseResult<OrdenCompraDetailDto>> CreateAsync(
        CreateOrdenCompraRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();
        if (request.Detalles.Count == 0)
        {
            errors.Add("Debes registrar al menos un detalle.");
        }

        if (request.Observacion is not null && string.IsNullOrWhiteSpace(request.Observacion))
        {
            errors.Add("La observacion no puede estar vacia.");
        }

        var proveedor = await proveedorRepository.FindByIdAsync(request.ProveedorId, cancellationToken);
        if (proveedor is null)
        {
            errors.Add("No se encontro el proveedor seleccionado.");
        }
        else if (!proveedor.Activo)
        {
            errors.Add("El proveedor seleccionado esta inactivo.");
        }

        var processedInsumoIds = new HashSet<long>();
        var details = new List<OrdenCompraRegistrationDetail>();

        foreach (var detail in request.Detalles)
        {
            if (!processedInsumoIds.Add(detail.InsumoId))
            {
                errors.Add($"El insumo {detail.InsumoId} no debe repetirse en la orden.");
                continue;
            }

            var insumo = await insumoRepository.FindByIdAsync(detail.InsumoId, cancellationToken);
            if (insumo is null)
            {
                errors.Add($"No se encontro el insumo {detail.InsumoId}.");
                continue;
            }

            if (!insumo.Activo)
            {
                errors.Add($"El insumo {insumo.Codigo} esta inactivo.");
                continue;
            }

            if (detail.CantidadSolicitada <= 0)
            {
                errors.Add($"La cantidad solicitada del insumo {insumo.Codigo} debe ser mayor que 0.");
                continue;
            }

            if (detail.CostoUnitarioEstimado is < 0)
            {
                errors.Add($"El costo estimado del insumo {insumo.Codigo} no puede ser negativo.");
                continue;
            }

            if (detail.Observacion is not null && string.IsNullOrWhiteSpace(detail.Observacion))
            {
                errors.Add($"La observacion del insumo {insumo.Codigo} no puede estar vacia.");
                continue;
            }

            details.Add(new OrdenCompraRegistrationDetail(
                detail.InsumoId,
                decimal.Round(detail.CantidadSolicitada, 4),
                detail.CostoUnitarioEstimado is null ? null : decimal.Round(detail.CostoUnitarioEstimado.Value, 4),
                NormalizeNullable(detail.Observacion)));
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync("OC", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        var orderId = await ordenCompraRepository.CreateAsync(
            new OrdenCompraRegistration(
                codigo,
                request.ProveedorId,
                request.FechaEmision.Date,
                NormalizeNullable(request.Observacion),
                actorId,
                details),
            cancellationToken);

        return await GetByIdAsync(orderId, cancellationToken);
    }

    public async Task<UseCaseResult<OrdenCompraDetailDto>> ApproveAsync(
        long id,
        long actorId,
        CancellationToken cancellationToken)
    {
        var ordenCompra = await ordenCompraRepository.FindByIdAsync(id, cancellationToken);
        if (ordenCompra is null)
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se encontro la orden de compra.");
        }

        if (!string.Equals(ordenCompra.Estado, "PENDIENTE", StringComparison.OrdinalIgnoreCase))
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.Conflict,
                "Solo se pueden aprobar ordenes en estado PENDIENTE.");
        }

        await ordenCompraRepository.SetApprovedAsync(id, dateTimeProvider.Now, actorId, cancellationToken);
        return await GetByIdAsync(id, cancellationToken);
    }

    public async Task<UseCaseResult<OrdenCompraDetailDto>> RejectAsync(
        long id,
        OrdenCompraDecisionRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Motivo))
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.Validation,
                "Debes indicar el motivo del rechazo.");
        }

        var ordenCompra = await ordenCompraRepository.FindByIdAsync(id, cancellationToken);
        if (ordenCompra is null)
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se encontro la orden de compra.");
        }

        if (!string.Equals(ordenCompra.Estado, "PENDIENTE", StringComparison.OrdinalIgnoreCase))
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.Conflict,
                "Solo se pueden rechazar ordenes en estado PENDIENTE.");
        }

        await ordenCompraRepository.SetRejectedAsync(
            id,
            request.Motivo.Trim(),
            dateTimeProvider.Now,
            actorId,
            cancellationToken);

        return await GetByIdAsync(id, cancellationToken);
    }

    public async Task<UseCaseResult<OrdenCompraDetailDto>> CancelAsync(
        long id,
        OrdenCompraDecisionRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Motivo))
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.Validation,
                "Debes indicar el motivo de la anulacion.");
        }

        var ordenCompra = await ordenCompraRepository.FindByIdAsync(id, cancellationToken);
        if (ordenCompra is null)
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se encontro la orden de compra.");
        }

        if (string.Equals(ordenCompra.Estado, "ANULADA", StringComparison.OrdinalIgnoreCase))
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.Conflict,
                "La orden de compra ya se encuentra anulada.");
        }

        if (string.Equals(ordenCompra.Estado, "PARCIALMENTE_RECIBIDA", StringComparison.OrdinalIgnoreCase) ||
            string.Equals(ordenCompra.Estado, "TOTALMENTE_RECIBIDA", StringComparison.OrdinalIgnoreCase))
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.Conflict,
                "No se puede anular una orden que ya tiene recepciones registradas.");
        }

        if (string.Equals(ordenCompra.Estado, "RECHAZADA", StringComparison.OrdinalIgnoreCase))
        {
            return UseCaseResult<OrdenCompraDetailDto>.Fail(
                InventarioErrorCodes.Conflict,
                "No se puede anular una orden ya rechazada.");
        }

        await ordenCompraRepository.SetCancelledAsync(
            id,
            request.Motivo.Trim(),
            dateTimeProvider.Now,
            actorId,
            cancellationToken);

        return await GetByIdAsync(id, cancellationToken);
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static OrdenCompraListItemDto MapListItem(OrdenCompra item) =>
        new(
            item.Id,
            item.Codigo,
            item.ProveedorId,
            item.ProveedorRazonSocial,
            item.FechaEmision,
            item.FechaAprobacion,
            item.AprobadoPorUsuarioId,
            item.Estado,
            item.Observacion,
            item.Motivo,
            item.CreadoEn,
            item.CreadoPorUsuarioId,
            item.ActualizadoEn,
            item.ActualizadoPorUsuarioId,
            item.TotalItems,
            item.CantidadTotalSolicitada,
            item.CantidadTotalRecibida,
            item.MontoTotalEstimado);

    private static OrdenCompraDetailDto MapDetail(OrdenCompra order, IReadOnlyCollection<OrdenCompraDetalle> details) =>
        new(
            order.Id,
            order.Codigo,
            order.ProveedorId,
            order.ProveedorRazonSocial,
            order.FechaEmision,
            order.FechaAprobacion,
            order.AprobadoPorUsuarioId,
            order.Estado,
            order.Observacion,
            order.Motivo,
            order.CreadoEn,
            order.CreadoPorUsuarioId,
            order.ActualizadoEn,
            order.ActualizadoPorUsuarioId,
            details.Select(detail => new OrdenCompraDetalleDto(
                detail.Id,
                detail.InsumoId,
                detail.InsumoCodigo,
                detail.InsumoNombre,
                detail.UnidadMedidaCodigo,
                detail.UnidadMedidaNombre,
                detail.CantidadSolicitada,
                detail.CantidadRecibida,
                detail.SaldoPendiente,
                detail.CostoUnitarioEstimado,
                detail.MontoEstimado,
                detail.Observacion)).ToArray());
}
