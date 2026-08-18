using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Salidas;

public sealed class SalidaInventarioService(
    ISalidaInventarioRepository salidaInventarioRepository,
    IInsumoRepository insumoRepository,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<SalidaInventarioListItemDto>> ListAsync(
        SalidaInventarioFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await salidaInventarioRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapListItem).ToArray();
    }

    public async Task<UseCaseResult<SalidaInventarioDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var salida = await salidaInventarioRepository.FindByIdAsync(id, cancellationToken);
        if (salida is null)
        {
            return UseCaseResult<SalidaInventarioDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se encontro la salida de inventario.");
        }

        var details = await salidaInventarioRepository.ListDetailsAsync(id, cancellationToken);
        return UseCaseResult<SalidaInventarioDetailDto>.Ok(MapDetail(salida, details));
    }

    public Task<UseCaseResult<SalidaInventarioDetailDto>> RegisterGeneralAsync(
        RegistrarSalidaGeneralRequestDto request,
        long actorId,
        CancellationToken cancellationToken) =>
        RegisterAsync(
            "GENERAL",
            sequenceCode: "SI",
            orderProductionId: null,
            orderProcessId: null,
            request.Motivo,
            request.Observacion,
            request.Detalles,
            actorId,
            cancellationToken);

    public Task<UseCaseResult<SalidaInventarioDetailDto>> RegisterProcessAsync(
        RegistrarSalidaProcesoRequestDto request,
        long actorId,
        CancellationToken cancellationToken) =>
        RegisterAsync(
            "PROCESO",
            sequenceCode: "SI",
            request.OrdenProduccionId,
            request.OrdenProcesoId,
            string.IsNullOrWhiteSpace(request.Motivo) ? "Consumo por proceso productivo" : request.Motivo,
            request.Observacion,
            request.Detalles,
            actorId,
            cancellationToken);

    public Task<UseCaseResult<SalidaInventarioDetailDto>> RegisterSupplierReturnAsync(
        RegistrarDevolucionProveedorRequestDto request,
        long actorId,
        CancellationToken cancellationToken) =>
        RegisterAsync(
            "DEVOLUCION_PROVEEDOR",
            sequenceCode: "SI",
            null,
            null,
            request.Motivo,
            request.Observacion,
            request.Detalles,
            actorId,
            cancellationToken);

    public Task<UseCaseResult<SalidaInventarioDetailDto>> RegisterNegativeAdjustmentAsync(
        RegistrarAjusteNegativoRequestDto request,
        long actorId,
        CancellationToken cancellationToken) =>
        RegisterAsync(
            "AJUSTE_NEGATIVO",
            sequenceCode: "AJ",
            null,
            null,
            request.Motivo,
            request.Observacion,
            request.Detalles,
            actorId,
            cancellationToken);

    private async Task<UseCaseResult<SalidaInventarioDetailDto>> RegisterAsync(
        string tipoSalida,
        string sequenceCode,
        long? orderProductionId,
        long? orderProcessId,
        string? motivo,
        string? observacion,
        IReadOnlyCollection<RegistrarSalidaDetalleRequestDto> requestDetails,
        long actorId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(motivo))
        {
            errors.Add("El motivo es obligatorio.");
        }

        if (observacion is not null && string.IsNullOrWhiteSpace(observacion))
        {
            errors.Add("La observacion no puede estar vacia.");
        }

        if (requestDetails.Count == 0)
        {
            errors.Add("Debes registrar al menos un detalle.");
        }

        if (string.Equals(tipoSalida, "PROCESO", StringComparison.OrdinalIgnoreCase) && orderProductionId is null or <= 0)
        {
            errors.Add("La salida por proceso requiere una orden de produccion valida.");
        }

        var processedInsumoIds = new HashSet<long>();
        var details = new List<SalidaInventarioRegistrationDetail>();

        foreach (var detail in requestDetails)
        {
            if (!processedInsumoIds.Add(detail.InsumoId))
            {
                errors.Add($"El insumo {detail.InsumoId} no debe repetirse en la salida.");
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

            if (detail.Cantidad <= 0)
            {
                errors.Add($"La cantidad del insumo {insumo.Codigo} debe ser mayor que 0.");
                continue;
            }

            if (detail.Observacion is not null && string.IsNullOrWhiteSpace(detail.Observacion))
            {
                errors.Add($"La observacion del insumo {insumo.Codigo} no puede estar vacia.");
                continue;
            }

            details.Add(new SalidaInventarioRegistrationDetail(
                detail.InsumoId,
                decimal.Round(detail.Cantidad, 4),
                NormalizeNullable(detail.Observacion)));
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<SalidaInventarioDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync(sequenceCode, cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<SalidaInventarioDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        long salidaId;
        try
        {
            salidaId = await salidaInventarioRepository.RegisterAsync(
                new SalidaInventarioRegistration(
                    codigo,
                    tipoSalida,
                    orderProductionId,
                    orderProcessId,
                    dateTimeProvider.Now,
                    motivo!.Trim(),
                    NormalizeNullable(observacion),
                    actorId,
                    details),
                cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<SalidaInventarioDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        return await GetByIdAsync(salidaId, cancellationToken);
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static SalidaInventarioListItemDto MapListItem(SalidaInventario item) =>
        new(
            item.Id,
            item.Codigo,
            item.TipoSalida,
            item.OrdenProduccionId,
            item.OrdenProcesoId,
            item.FechaSalida,
            item.Motivo,
            item.Observacion,
            item.Estado,
            item.CreadoPorUsuarioId,
            item.CreadoEn,
            item.TotalItems,
            item.CantidadTotal,
            item.MontoTotal);

    private static SalidaInventarioDetailDto MapDetail(SalidaInventario header, IReadOnlyCollection<SalidaInventarioDetalle> details) =>
        new(
            header.Id,
            header.Codigo,
            header.TipoSalida,
            header.OrdenProduccionId,
            header.OrdenProcesoId,
            header.FechaSalida,
            header.Motivo,
            header.Observacion,
            header.Estado,
            header.CreadoPorUsuarioId,
            header.CreadoEn,
            details.Select(detail => new SalidaInventarioDetalleDto(
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
                detail.Observacion)).ToArray());
}
