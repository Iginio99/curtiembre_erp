using ErpCurtiembre.Modules.Configuracion.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.DTOs;
using ErpCurtiembre.Modules.Inventario.Application.Ports;
using ErpCurtiembre.Modules.Inventario.Application.Support;
using ErpCurtiembre.Modules.Inventario.Domain.Entities;
using ErpCurtiembre.Shared.Time;

namespace ErpCurtiembre.Modules.Inventario.Application.UseCases.Ajustes;

public sealed class AjusteInventarioService(
    IAjusteInventarioRepository ajusteInventarioRepository,
    IInsumoRepository insumoRepository,
    IDocumentSequenceService documentSequenceService,
    IDateTimeProvider dateTimeProvider)
{
    public async Task<IReadOnlyCollection<AjusteInventarioListItemDto>> ListAsync(
        AjusteInventarioFiltersDto filters,
        CancellationToken cancellationToken)
    {
        var items = await ajusteInventarioRepository.ListAsync(filters, cancellationToken);
        return items.Select(MapListItem).ToArray();
    }

    public async Task<UseCaseResult<AjusteInventarioDetailDto>> GetByIdAsync(long id, CancellationToken cancellationToken)
    {
        var ajuste = await ajusteInventarioRepository.FindByIdAsync(id, cancellationToken);
        if (ajuste is null)
        {
            return UseCaseResult<AjusteInventarioDetailDto>.Fail(
                InventarioErrorCodes.NotFound,
                "No se encontro el ajuste de inventario.");
        }

        var details = await ajusteInventarioRepository.ListDetailsAsync(id, cancellationToken);
        return UseCaseResult<AjusteInventarioDetailDto>.Ok(MapDetail(ajuste, details));
    }

    public Task<UseCaseResult<AjusteInventarioDetailDto>> RegisterPositiveAsync(
        RegistrarAjusteInventarioRequestDto request,
        long actorId,
        CancellationToken cancellationToken) =>
        RegisterAsync("POSITIVO", request, actorId, cancellationToken);

    public Task<UseCaseResult<AjusteInventarioDetailDto>> RegisterNegativeAsync(
        RegistrarAjusteInventarioRequestDto request,
        long actorId,
        CancellationToken cancellationToken) =>
        RegisterAsync("NEGATIVO", request, actorId, cancellationToken);

    private async Task<UseCaseResult<AjusteInventarioDetailDto>> RegisterAsync(
        string tipoAjuste,
        RegistrarAjusteInventarioRequestDto request,
        long actorId,
        CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        if (string.IsNullOrWhiteSpace(request.Motivo))
        {
            errors.Add("El motivo es obligatorio.");
        }

        if (request.Observacion is not null && string.IsNullOrWhiteSpace(request.Observacion))
        {
            errors.Add("La observacion no puede estar vacia.");
        }

        if (request.Detalles.Count == 0)
        {
            errors.Add("Debes registrar al menos un detalle.");
        }

        var processedInsumoIds = new HashSet<long>();
        var details = new List<AjusteInventarioRegistrationDetail>();

        foreach (var detail in request.Detalles)
        {
            if (!processedInsumoIds.Add(detail.InsumoId))
            {
                errors.Add($"El insumo {detail.InsumoId} no debe repetirse en el ajuste.");
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

            if (string.Equals(tipoAjuste, "POSITIVO", StringComparison.OrdinalIgnoreCase))
            {
                if (detail.CostoUnitario is null)
                {
                    errors.Add($"El costo unitario del insumo {insumo.Codigo} es obligatorio para ajuste positivo.");
                    continue;
                }

                if (detail.CostoUnitario < 0)
                {
                    errors.Add($"El costo unitario del insumo {insumo.Codigo} no puede ser negativo.");
                    continue;
                }
            }

            if (string.Equals(tipoAjuste, "NEGATIVO", StringComparison.OrdinalIgnoreCase) &&
                detail.CostoUnitario is not null &&
                detail.CostoUnitario < 0)
            {
                errors.Add($"El costo unitario del insumo {insumo.Codigo} no puede ser negativo.");
                continue;
            }

            details.Add(new AjusteInventarioRegistrationDetail(
                detail.InsumoId,
                decimal.Round(detail.Cantidad, 4),
                detail.CostoUnitario is null ? null : decimal.Round(detail.CostoUnitario.Value, 4)));
        }

        if (errors.Count > 0)
        {
            return UseCaseResult<AjusteInventarioDetailDto>.Fail(InventarioErrorCodes.Validation, string.Join(" ", errors));
        }

        string codigo;
        try
        {
            codigo = await documentSequenceService.GenerateNextAsync("AJ", cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<AjusteInventarioDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        long ajusteId;
        try
        {
            ajusteId = await ajusteInventarioRepository.RegisterAsync(
                new AjusteInventarioRegistration(
                    codigo,
                    tipoAjuste,
                    dateTimeProvider.Now,
                    request.Motivo.Trim(),
                    NormalizeNullable(request.Observacion),
                    actorId,
                    details),
                cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            return UseCaseResult<AjusteInventarioDetailDto>.Fail(InventarioErrorCodes.Conflict, exception.Message);
        }

        return await GetByIdAsync(ajusteId, cancellationToken);
    }

    private static string? NormalizeNullable(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static AjusteInventarioListItemDto MapListItem(AjusteInventario item) =>
        new(
            item.Id,
            item.Codigo,
            item.TipoAjuste,
            item.FechaAjuste,
            item.Motivo,
            item.Observacion,
            item.UsuarioResponsableId,
            item.TotalItems,
            item.CantidadTotal,
            item.MontoTotal);

    private static AjusteInventarioDetailDto MapDetail(AjusteInventario header, IReadOnlyCollection<AjusteInventarioDetalle> details) =>
        new(
            header.Id,
            header.Codigo,
            header.TipoAjuste,
            header.FechaAjuste,
            header.Motivo,
            header.Observacion,
            header.UsuarioResponsableId,
            details.Select(detail => new AjusteInventarioDetalleDto(
                detail.Id,
                detail.InsumoId,
                detail.InsumoCodigo,
                detail.InsumoNombre,
                detail.Cantidad,
                detail.CostoUnitario,
                detail.CostoTotal,
                detail.StockActual,
                detail.UnidadMedidaCodigo,
                detail.UnidadMedidaNombre)).ToArray());
}
